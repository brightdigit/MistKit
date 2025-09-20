//
//  ServerToServerAuthManager.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import Foundation
public import Crypto

// Forward declaration for MistKitConfiguration
#if canImport(MistKit)
// Configuration will be available when imported as part of MistKit
#endif

/// Token manager for server-to-server authentication using ECDSA P-256 signing
/// Provides enterprise-level authentication for CloudKit Web Services
/// Available on macOS 11.0+, iOS 14.0+, tvOS 14.0+, watchOS 7.0+, and Linux
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public final class ServerToServerAuthManager: TokenManager, Sendable {
  private let keyID: String
  private let privateKey: P256.Signing.PrivateKey
  private let credentials: TokenCredentials
  private let refreshPolicy: TokenRefreshPolicy
  private let retryPolicy: RetryPolicy
  private let storage: (any TokenStorage)?

  // Key rotation scheduler state
  private let taskState = TaskState()
  private let rotationSubject = AsyncStream<KeyRotationEvent>.makeStream()

  /// Actor to manage task state safely
  private actor TaskState {
    private var rotationTask: Task<Void, Never>?

    func setTask(_ task: Task<Void, Never>?) {
      rotationTask?.cancel()
      rotationTask = task
    }

    func cancelTask() {
      rotationTask?.cancel()
      rotationTask = nil
    }
  }

  /// Events emitted during key rotation operations
  public enum KeyRotationEvent: Sendable {
    case rotationStarted(keyID: String)
    case rotationCompleted(oldKeyID: String, newKeyID: String)
    case rotationFailed(keyID: String, error: any Error)
    case rotationScheduled(keyID: String, nextRotation: Date)
  }

  /// Stream of key rotation events
  public var rotationEvents: AsyncStream<KeyRotationEvent> {
    rotationSubject.stream
  }

  /// Creates a new server-to-server authentication manager
  /// - Parameters:
  ///   - keyID: The key identifier from Apple Developer Console
  ///   - privateKey: The ECDSA P-256 private key
  ///   - refreshPolicy: Token refresh policy (default: manual)
  ///   - retryPolicy: Retry policy for failed operations (default: .default)
  ///   - storage: Optional storage for persistence (default: nil for in-memory only)
  public init(
    keyID: String,
    privateKey: P256.Signing.PrivateKey,
    refreshPolicy: TokenRefreshPolicy = .manual,
    retryPolicy: RetryPolicy = .default,
    storage: (any TokenStorage)? = nil
  ) {
    self.keyID = keyID
    self.privateKey = privateKey
    self.refreshPolicy = refreshPolicy
    self.retryPolicy = retryPolicy
    self.storage = storage
    self.credentials = TokenCredentials.serverToServer(
      keyID: keyID,
      privateKey: privateKey.rawRepresentation
    )

    // Start rotation scheduler if policy supports it
    if refreshPolicy.supportsAutomaticRefresh {
      startRotationScheduler()
    }
  }

  deinit {
    let taskState = self.taskState
    Task.detached { await taskState.cancelTask() }
    rotationSubject.continuation.finish()
  }

  /// Convenience initializer with private key data
  /// - Parameters:
  ///   - keyID: The key identifier from Apple Developer Console
  ///   - privateKeyData: The private key as raw data (32 bytes for P-256)
  ///   - refreshPolicy: Token refresh policy (default: manual)
  ///   - retryPolicy: Retry policy for failed operations (default: .default)
  ///   - storage: Optional storage for persistence (default: nil for in-memory only)
  public convenience init(
    keyID: String,
    privateKeyData: Data,
    refreshPolicy: TokenRefreshPolicy = .manual,
    retryPolicy: RetryPolicy = .default,
    storage: (any TokenStorage)? = nil
  ) throws {
    let privateKey = try P256.Signing.PrivateKey(rawRepresentation: privateKeyData)
    self.init(
      keyID: keyID,
      privateKey: privateKey,
      refreshPolicy: refreshPolicy,
      retryPolicy: retryPolicy,
      storage: storage
    )
  }

  /// Convenience initializer with PEM-formatted private key
  /// - Parameters:
  ///   - keyID: The key identifier from Apple Developer Console
  ///   - pemString: The private key in PEM format
  ///   - refreshPolicy: Token refresh policy (default: manual)
  ///   - retryPolicy: Retry policy for failed operations (default: .default)
  ///   - storage: Optional storage for persistence (default: nil for in-memory only)
  public convenience init(
    keyID: String,
    pemString: String,
    refreshPolicy: TokenRefreshPolicy = .manual,
    retryPolicy: RetryPolicy = .default,
    storage: (any TokenStorage)? = nil
  ) throws {
    let privateKey = try P256.Signing.PrivateKey(pemRepresentation: pemString)
    self.init(
      keyID: keyID,
      privateKey: privateKey,
      refreshPolicy: refreshPolicy,
      retryPolicy: retryPolicy,
      storage: storage
    )
  }

  // MARK: - TokenManager Protocol

  public let supportsRefresh = true // Server keys can be rotated

  public var hasCredentials: Bool {
    get async {
      return !keyID.isEmpty
    }
  }

  public func validateCredentials() async throws -> Bool {
    guard !keyID.isEmpty else {
      throw TokenManagerError.invalidCredentials(reason: "Key ID is empty")
    }

    // Validate key ID format (typically alphanumeric with specific length)
    guard keyID.count >= 8 else {
      throw TokenManagerError.invalidCredentials(
        reason: "Key ID appears to be too short (minimum 8 characters)"
      )
    }

    // Try to create a test signature to validate the private key
    do {
      let testData = "test".data(using: .utf8)!
      _ = try privateKey.signature(for: testData)
    } catch {
      throw TokenManagerError.invalidCredentials(
        reason: "Private key is invalid or corrupted: \(error.localizedDescription)"
      )
    }

    return true
  }

  public func getCurrentCredentials() async throws -> TokenCredentials? {
    // Validate first
    _ = try await validateCredentials()
    return credentials
  }

  public func refreshCredentials() async throws -> TokenCredentials? {
    // For server-to-server auth, "refresh" means we regenerate credentials
    // with the same key (useful for updating metadata or timestamps)
    return TokenCredentials.serverToServer(
      keyID: keyID,
      privateKey: privateKey.rawRepresentation
    )
  }
}

// MARK: - Key Rotation Scheduler

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension ServerToServerAuthManager {
  /// Starts the automatic key rotation scheduler based on refresh policy
  private func startRotationScheduler() {
    guard refreshPolicy.supportsAutomaticRefresh else { return }

    let task = Task<Void, Never> { [weak self] in
      await self?.runRotationScheduler()
    }
    Task { await taskState.setTask(task) }
  }

  /// Runs the key rotation scheduler loop
  private func runRotationScheduler() async {
    while !Task.isCancelled {
      do {
        let nextRotationDate = calculateNextRotationDate()

        // Emit scheduled event
        rotationSubject.continuation.yield(.rotationScheduled(keyID: keyID, nextRotation: nextRotationDate))

        // Wait until the scheduled rotation time
        let now = Date()
        if nextRotationDate > now {
          let delay = nextRotationDate.timeIntervalSince(now)
          let nanoseconds = UInt64(delay * 1_000_000_000)
          try await Task.sleep(nanoseconds: nanoseconds)
        }

        // Check if we're still running after sleep
        guard !Task.isCancelled else { break }

        // Perform key rotation (this would typically involve external key management)
        await performScheduledRotation()

      } catch {
        // If sleeping was cancelled, exit gracefully
        if error is CancellationError {
          break
        }

        // For other errors, wait a bit before retrying
        try? await Task.sleep(nanoseconds: 60_000_000_000) // 60 seconds
      }
    }
  }

  /// Calculates the next rotation date based on refresh policy
  private func calculateNextRotationDate() -> Date {
    let now = Date()

    switch refreshPolicy {
    case .periodic(let interval):
      return now.addingTimeInterval(interval)
    case .onExpiry:
      // For server-to-server keys, we don't have a specific expiry
      // Default to 24 hours for onExpiry policy
      return now.addingTimeInterval(24 * 60 * 60)
    case .manual:
      // This shouldn't be called for manual policy
      return now.addingTimeInterval(Double.greatestFiniteMagnitude)
    }
  }

  /// Performs the actual key rotation (placeholder for external key management integration)
  private func performScheduledRotation() async {
    rotationSubject.continuation.yield(.rotationStarted(keyID: keyID))

    do {
      // In a real implementation, this would:
      // 1. Generate a new key pair
      // 2. Register the new key with Apple's key management system
      // 3. Update the keyID and privateKey properties
      // 4. Store the new credentials if storage is available

      // For now, we'll just emit a completion event with the same key
      // since we can't actually perform key rotation without external integration
      rotationSubject.continuation.yield(.rotationCompleted(oldKeyID: keyID, newKeyID: keyID))

      // Store updated credentials if storage is available
      if let storage = storage {
        try await storage.store(credentials, identifier: keyID)
      }

    } catch {
      rotationSubject.continuation.yield(.rotationFailed(keyID: keyID, error: error))
    }
  }

  /// Manually triggers key rotation (can be called regardless of refresh policy)
  /// - Parameters:
  ///   - newKeyID: The new key identifier
  ///   - newPrivateKey: The new private key
  /// - Returns: New TokenCredentials with rotated key
  public func rotateKey(to newKeyID: String, privateKey newPrivateKey: P256.Signing.PrivateKey) async throws -> TokenCredentials {
    let oldKeyID = keyID

    rotationSubject.continuation.yield(.rotationStarted(keyID: oldKeyID))

    do {
      // Create new credentials with rotated key
      let newCredentials = TokenCredentials.serverToServer(
        keyID: newKeyID,
        privateKey: newPrivateKey.rawRepresentation
      )

      // Store new credentials if storage is available
      if let storage = storage {
        // Store new credentials and remove old ones
        try await storage.store(newCredentials, identifier: newKeyID)
        try await storage.remove(identifier: oldKeyID)
      }

      rotationSubject.continuation.yield(.rotationCompleted(oldKeyID: oldKeyID, newKeyID: newKeyID))

      return newCredentials

    } catch {
      rotationSubject.continuation.yield(.rotationFailed(keyID: oldKeyID, error: error))
      throw error
    }
  }

  /// Stops the automatic key rotation scheduler
  public func stopRotationScheduler() {
    Task { await taskState.cancelTask() }
  }

  /// Returns the current refresh policy
  public var currentRefreshPolicy: TokenRefreshPolicy {
    refreshPolicy
  }

  /// Returns the current retry policy
  public var currentRetryPolicy: RetryPolicy {
    retryPolicy
  }
}

// MARK: - Request Signing Methods

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension ServerToServerAuthManager {
  /// Signs a CloudKit Web Services request
  /// - Parameters:
  ///   - requestBody: The HTTP request body (for POST requests)
  ///   - webServiceURL: The full CloudKit Web Services URL
  ///   - date: The request date (defaults to current date)
  /// - Returns: Signature components for CloudKit headers
  public func signRequest(
    requestBody: Data?,
    webServiceURL: String,
    date: Date = Date()
  ) throws -> RequestSignature {
    // Create the signature payload according to Apple's CloudKit specification:
    // [Current Date]:[Base64 Body Hash]:[Web Service URL Subpath]
    // Apple requires ISO8601 format without milliseconds (e.g., 2016-01-25T22:15:43Z)
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
    let iso8601Date = formatter.string(from: date)

    // Calculate SHA-256 hash of request body, then base64 encode (per Apple docs)
    let bodyHash: String
    if let requestBody = requestBody {
      let hash = SHA256.hash(data: requestBody)
      bodyHash = Data(hash).base64EncodedString()
    } else {
      bodyHash = ""
    }

    let signaturePayload = "\(iso8601Date):\(bodyHash):\(webServiceURL)"
    
    // Debug output for troubleshooting
    print("🔍 Debug - Signature Payload:")
    print("   Date: \(iso8601Date)")
    print("   Body Hash: \(bodyHash)")
    print("   Web Service URL: \(webServiceURL)")
    print("   Full Payload: \(signaturePayload)")

    guard let payloadData = signaturePayload.data(using: .utf8) else {
      throw TokenManagerError.internalError(reason: "Failed to encode signature payload")
    }

    // Create ECDSA signature
    let signature = try privateKey.signature(for: payloadData)
    let signatureBase64 = signature.derRepresentation.base64EncodedString()

    return RequestSignature(
      keyID: keyID,
      date: iso8601Date,
      signature: signatureBase64
    )
  }

  /// The key identifier
  public var keyIdentifier: String {
    keyID
  }

  /// Returns the public key for verification purposes
  public var publicKey: P256.Signing.PublicKey {
    privateKey.publicKey
  }

  /// Creates credentials with additional metadata
  /// - Parameter metadata: Additional metadata to include
  /// - Returns: TokenCredentials with metadata
  public func credentialsWithMetadata(_ metadata: [String: String]) -> TokenCredentials {
    TokenCredentials(
      method: .serverToServer(keyID: keyID, privateKey: privateKey.rawRepresentation),
      metadata: metadata
    )
  }

  /// Creates new credentials with rotated key (for key rotation)
  /// - Parameter newPrivateKey: The new private key
  /// - Returns: New TokenCredentials with updated key
  /// - Note: This creates new credentials but doesn't update the manager's internal key
  public func credentialsWithRotatedKey(to newPrivateKey: P256.Signing.PrivateKey) -> TokenCredentials {
    // Note: This would typically require updating the keyID as well in a real rotation
    return TokenCredentials.serverToServer(
      keyID: keyID,
      privateKey: newPrivateKey.rawRepresentation
    )
  }

  /// Creates a MistKitConfiguration for server-to-server authentication
  /// This automatically configures the public database as required for server-to-server auth
  /// - Parameters:
  ///   - container: The CloudKit container identifier
  ///   - environment: The CloudKit environment
  /// - Returns: A properly configured MistKitConfiguration for server-to-server use
  public static func configuration(
    container: String,
    environment: Environment
  ) -> MistKitConfiguration {
    return MistKitConfiguration.serverToServer(
      container: container,
      environment: environment
    )
  }
}

// MARK: - Request Signature Type

/// CloudKit Web Services request signature components
public struct RequestSignature: Sendable {
  /// The key identifier for X-Apple-CloudKit-Request-KeyID header
  public let keyID: String

  /// The ISO8601 date string for X-Apple-CloudKit-Request-ISO8601Date header
  public let date: String

  /// The base64-encoded signature for X-Apple-CloudKit-Request-SignatureV1 header
  public let signature: String

  /// Creates CloudKit request headers from this signature
  public var headers: [String: String] {
    [
      "X-Apple-CloudKit-Request-KeyID": keyID,
      "X-Apple-CloudKit-Request-ISO8601Date": date,
      "X-Apple-CloudKit-Request-SignatureV1": signature
    ]
  }
}
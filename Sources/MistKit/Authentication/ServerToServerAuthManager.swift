//
//  ServerToServerAuthManager.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import Crypto
public import Foundation

// Forward declaration for MistKitConfiguration
#if canImport(MistKit)
  // Configuration will be available when imported as part of MistKit
#endif

/// Token manager for server-to-server authentication using ECDSA P-256 signing
/// Provides enterprise-level authentication for CloudKit Web Services
/// Available on macOS 11.0+, iOS 14.0+, tvOS 14.0+, watchOS 7.0+, and Linux
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public final class ServerToServerAuthManager: TokenManager, Sendable {
  internal let keyID: String
  internal let privateKey: @Sendable () throws -> P256.Signing.PrivateKey
  internal let credentials: TokenCredentials
  internal let refreshPolicy: TokenRefreshPolicy
  internal let retryPolicy: RetryPolicy
  internal let storage: (any TokenStorage)?

  // Key rotation scheduler state
  internal let taskState = TaskState()
  internal let rotationSubject = AsyncStream<KeyRotationEvent>.makeStream()

  /// Actor to manage task state safely
  internal actor TaskState {
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
    privateKeyCallback: @autoclosure @escaping @Sendable () throws -> P256.Signing.PrivateKey,
    refreshPolicy: TokenRefreshPolicy = .manual,
    retryPolicy: RetryPolicy = .default,
    storage: (any TokenStorage)? = nil
  ) throws {
    let privateKey = try privateKeyCallback()
    self.keyID = keyID
    self.privateKey = privateKeyCallback
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
    try self.init(
      keyID: keyID,
      privateKeyCallback: try P256.Signing.PrivateKey(rawRepresentation: privateKeyData),
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
    try self.init(
      keyID: keyID,
      privateKeyCallback: try P256.Signing.PrivateKey(pemRepresentation: pemString),
      refreshPolicy: refreshPolicy,
      retryPolicy: retryPolicy,
      storage: storage
    )
  }

  // MARK: - TokenManager Protocol

  public let supportsRefresh = true  // Server keys can be rotated

  public var hasCredentials: Bool {
    get async {
      !keyID.isEmpty
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
      _ = try privateKey().signature(for: testData)
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
    try TokenCredentials.serverToServer(
      keyID: keyID,
      privateKey: privateKey().rawRepresentation
    )
  }
}

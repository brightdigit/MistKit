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

  /// Creates a new server-to-server authentication manager
  /// - Parameters:
  ///   - keyID: The key identifier from Apple Developer Console
  ///   - privateKey: The ECDSA P-256 private key
  public init(keyID: String, privateKey: P256.Signing.PrivateKey) {
    self.keyID = keyID
    self.privateKey = privateKey
    self.credentials = TokenCredentials.serverToServer(
      keyID: keyID,
      privateKey: privateKey.rawRepresentation
    )
  }

  /// Convenience initializer with private key data
  /// - Parameters:
  ///   - keyID: The key identifier from Apple Developer Console
  ///   - privateKeyData: The private key as raw data (32 bytes for P-256)
  public convenience init(keyID: String, privateKeyData: Data) throws {
    let privateKey = try P256.Signing.PrivateKey(rawRepresentation: privateKeyData)
    self.init(keyID: keyID, privateKey: privateKey)
  }

  /// Convenience initializer with PEM-formatted private key
  /// - Parameters:
  ///   - keyID: The key identifier from Apple Developer Console
  ///   - pemString: The private key in PEM format
  public convenience init(keyID: String, pemString: String) throws {
    let privateKey = try P256.Signing.PrivateKey(pemRepresentation: pemString)
    self.init(keyID: keyID, privateKey: privateKey)
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
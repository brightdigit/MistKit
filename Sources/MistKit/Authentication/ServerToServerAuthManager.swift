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

#if canImport(Foundation)
  public import Foundation
#endif

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
  internal let privateKeyData: Data
  internal let credentials: TokenCredentials
  internal let storage: (any TokenStorage)?

  // MARK: - TokenManager Protocol

  public var hasCredentials: Bool {
    get async {
      !keyID.isEmpty
    }
  }

  /// Creates a new server-to-server authentication manager
  /// - Parameters:
  ///   - keyID: The key identifier from Apple Developer Console
  ///   - privateKeyCallback: A closure that returns the ECDSA P-256 private key
  ///   - storage: Optional storage for persistence (default: nil for in-memory only)
  public init(
    keyID: String,
    privateKeyCallback: @autoclosure @escaping @Sendable () throws -> P256.Signing.PrivateKey,
    storage: (any TokenStorage)? = nil
  ) throws {
    precondition(!keyID.isEmpty, "Key ID cannot be empty")
    let privateKey = try privateKeyCallback()
    self.keyID = keyID
    self.privateKeyData = privateKey.rawRepresentation
    self.storage = storage
    self.credentials = TokenCredentials.serverToServer(
      keyID: keyID,
      privateKey: privateKey.rawRepresentation
    )
  }

  /// Convenience initializer with private key data
  /// - Parameters:
  ///   - keyID: The key identifier from Apple Developer Console
  ///   - privateKeyData: The private key as raw data (32 bytes for P-256)
  ///   - storage: Optional storage for persistence (default: nil for in-memory only)
  public convenience init(
    keyID: String,
    privateKeyData: Data,
    storage: (any TokenStorage)? = nil
  ) throws {
    try self.init(
      keyID: keyID,
      privateKeyCallback: try P256.Signing.PrivateKey(rawRepresentation: privateKeyData),
      storage: storage
    )
  }

  /// Convenience initializer with PEM-formatted private key
  /// - Parameters:
  ///   - keyID: The key identifier from Apple Developer Console
  ///   - pemString: The private key in PEM format
  ///   - storage: Optional storage for persistence (default: nil for in-memory only)
  public convenience init(
    keyID: String,
    pemString: String,
    storage: (any TokenStorage)? = nil
  ) throws {
    do {
      try self.init(
        keyID: keyID,
        privateKeyCallback: try P256.Signing.PrivateKey(pemRepresentation: pemString),
        storage: storage
      )
    } catch {
      // Provide more specific error handling for PEM parsing failures
      if error.localizedDescription.contains("PEM") || error.localizedDescription.contains("format")
      {
        throw TokenManagerError.invalidCredentials(.invalidPEMFormat(error))
      } else {
        throw TokenManagerError.invalidCredentials(.privateKeyParseFailed(error))
      }
    }
  }

  // MARK: - Private Key Access

  /// Creates a P256.Signing.PrivateKey from the stored private key data
  /// This method is thread-safe as it creates a new instance each time
  internal func createPrivateKey() throws(TokenManagerError) -> P256.Signing.PrivateKey {
    do {
      return try P256.Signing.PrivateKey(rawRepresentation: privateKeyData)
    } catch {
      throw TokenManagerError.invalidCredentials(.privateKeyInvalidOrCorrupted(error))
    }
  }

  public func validateCredentials() async throws(TokenManagerError) -> Bool {
    guard !keyID.isEmpty else {
      throw TokenManagerError.invalidCredentials(.keyIdEmpty)
    }

    // Validate key ID format (typically alphanumeric with specific length)
    guard keyID.count >= 8 else {
      throw TokenManagerError.invalidCredentials(.keyIdTooShort)
    }

    // Try to create a test signature to validate the private key
    do {
      let testData = Data("test".utf8)
      let privateKey = try createPrivateKey()
      _ = try privateKey.signature(for: testData)
    } catch {
      throw TokenManagerError.invalidCredentials(.privateKeyInvalidOrCorrupted(error))
    }

    return true
  }

  public func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials? {
    // Validate first
    _ = try await validateCredentials()
    return credentials
  }
}

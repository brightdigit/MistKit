//
//  ServerToServerAuthManager.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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

/// Token manager for server-to-server authentication using ECDSA P-256 signing
/// Provides enterprise-level authentication for CloudKit Web Services
/// Available on macOS 11.0+, iOS 14.0+, tvOS 14.0+, watchOS 7.0+, and Linux
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public final class ServerToServerAuthManager: TokenManager, Sendable {
  internal let keyID: String
  internal let privateKeyData: Data
  internal let credentials: TokenCredentials

  // MARK: - TokenManager Protocol

  /// Indicates whether valid credentials are currently available
  public var hasCredentials: Bool {
    get async {
      !keyID.isEmpty
    }
  }

  /// Creates a new server-to-server authentication manager
  /// - Parameters:
  ///   - keyID: The key identifier from Apple Developer Console
  ///   - privateKeyCallback: A closure that returns the ECDSA P-256 private key
  /// - Throws: Error if the private key callback fails or the key is invalid
  public init(
    keyID: String,
    privateKeyCallback: @autoclosure @escaping @Sendable () throws -> P256.Signing.PrivateKey
  ) throws {
    let privateKey = try privateKeyCallback()
    self.keyID = keyID
    self.privateKeyData = privateKey.rawRepresentation
    self.credentials = TokenCredentials.serverToServer(
      keyID: keyID,
      privateKey: privateKey.rawRepresentation
    )
  }

  /// Convenience initializer with private key data
  /// - Parameters:
  ///   - keyID: The key identifier from Apple Developer Console
  ///   - privateKeyData: The private key as raw data (32 bytes for P-256)
  /// - Throws: Error if the private key data is invalid or cannot be parsed
  public convenience init(
    keyID: String,
    privateKeyData: Data
  ) throws {
    try self.init(
      keyID: keyID,
      privateKeyCallback: try P256.Signing.PrivateKey(rawRepresentation: privateKeyData)
    )
  }

  /// Convenience initializer with PEM-formatted private key
  /// - Parameters:
  ///   - keyID: The key identifier from Apple Developer Console
  ///   - pemString: The private key in PEM format
  /// - Throws: TokenManagerError if the PEM string is invalid or cannot be parsed
  public convenience init(
    keyID: String,
    pemString: String
  ) throws {
    do {
      try self.init(
        keyID: keyID,
        privateKeyCallback: try P256.Signing.PrivateKey(pemRepresentation: pemString)
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

  /// Validates the stored credentials for format and completeness
  /// - Returns: true if credentials are valid, false otherwise
  /// - Throws: TokenManagerError if credentials are invalid
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

  /// Retrieves the current credentials for authentication
  /// - Returns: The current token credentials, or nil if not available
  /// - Throws: TokenManagerError if credentials are invalid
  public func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials? {
    // Validate first
    _ = try await validateCredentials()
    return credentials
  }
}

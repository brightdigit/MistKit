//
//  ServerToServerAuthManager.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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

public import Crypto
public import Foundation

/// Token manager for server-to-server authentication using ECDSA P-256 signing.
/// Provides enterprise-level authentication for CloudKit Web Services.
/// Available on macOS 11.0+, iOS 14.0+, tvOS 14.0+, watchOS 7.0+, and Linux.
public final class ServerToServerAuthManager: TokenManager, Sendable {
  internal let keyID: String
  internal let privateKey: P256.Signing.PrivateKey
  internal let bodyBufferLimit: Int

  // MARK: - TokenManager Protocol

  /// Indicates whether valid credentials are currently available.
  public var hasCredentials: Bool {
    get async {
      !keyID.isEmpty
    }
  }

  /// The raw representation of the private key (32 bytes for P-256).
  internal var privateKeyData: Data {
    privateKey.rawRepresentation
  }

  /// Creates a new server-to-server authentication manager.
  /// - Parameters:
  ///   - keyID: The key identifier from Apple Developer Console.
  ///   - privateKeyCallback: A closure that returns the ECDSA P-256 private key.
  ///   - bodyBufferLimit: Maximum body size to buffer for signing.
  /// - Throws: If the private key callback fails or the key is invalid.
  public init(
    keyID: String,
    privateKeyCallback: @autoclosure @escaping @Sendable () throws -> P256.Signing.PrivateKey,
    bodyBufferLimit: Int = ServerToServerAuthenticator.defaultBodyBufferLimit
  ) throws {
    let privateKey = try privateKeyCallback()
    self.keyID = keyID
    self.privateKey = privateKey
    self.bodyBufferLimit = bodyBufferLimit
  }

  /// Convenience initializer with private key data.
  public convenience init(
    keyID: String,
    privateKeyData: Data,
    bodyBufferLimit: Int = ServerToServerAuthenticator.defaultBodyBufferLimit
  ) throws {
    try self.init(
      keyID: keyID,
      privateKeyCallback: try P256.Signing.PrivateKey(rawRepresentation: privateKeyData),
      bodyBufferLimit: bodyBufferLimit
    )
  }

  /// Convenience initializer with PEM-formatted private key.
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  public convenience init(
    keyID: String,
    pemString: String,
    bodyBufferLimit: Int = ServerToServerAuthenticator.defaultBodyBufferLimit
  ) throws {
    do {
      try self.init(
        keyID: keyID,
        privateKeyCallback: try P256.Signing.PrivateKey(pemRepresentation: pemString),
        bodyBufferLimit: bodyBufferLimit
      )
    } catch {
      if error.localizedDescription.contains("PEM")
        || error.localizedDescription.contains("format")
      {
        throw TokenManagerError.invalidCredentials(.invalidPEMFormat(error))
      }
      throw TokenManagerError.invalidCredentials(.privateKeyParseFailed(error))
    }
  }

  /// Validates the stored credentials for format and completeness.
  public func validateCredentials() async throws(TokenManagerError) -> Bool {
    _ = try ServerToServerAuthenticator(
      keyID: keyID,
      privateKey: privateKey,
      bodyBufferLimit: bodyBufferLimit
    )
    return true
  }

  /// Returns the server-to-server authenticator, after validation.
  public func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)? {
    try ServerToServerAuthenticator(
      keyID: keyID,
      privateKey: privateKey,
      bodyBufferLimit: bodyBufferLimit
    )
  }
}

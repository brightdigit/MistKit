//
//  ServerToServerAuthenticator.swift
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
public import HTTPTypes
public import OpenAPIRuntime

/// Server-to-server authentication: signs each request with an ECDSA P-256
/// private key and attaches the signature, key ID, and ISO-8601 date as
/// CloudKit-specific HTTP headers.
///
/// The body is read once during signing. To keep downstream middleware
/// working with the same bytes regardless of `HTTPBody` iteration behavior,
/// `authenticate(request:body:)` reassigns `body` to a buffered copy.
public struct ServerToServerAuthenticator: Authenticator {
  private struct WireFormat: Codable {
    let keyID: String
    let privateKey: String  // base64-encoded raw representation
    let bodyBufferLimit: Int?
  }

  /// Stable storage key (`"server-to-server"`).
  public static let storageKey: String = "server-to-server"

  /// Default upper bound (1 MiB) for buffering the request body when signing.
  public static let defaultBodyBufferLimit: Int = 1_024 * 1_024

  /// The CloudKit key identifier from Apple Developer Console.
  public let keyID: String

  /// The ECDSA P-256 private key used to sign requests.
  public let privateKey: P256.Signing.PrivateKey

  /// Maximum number of body bytes to buffer for signing.
  /// Requests with larger bodies will fail to sign.
  public let bodyBufferLimit: Int

  /// Identifier derived from the key ID so that distinct service-account
  /// keys can be persisted side by side.
  public var defaultStorageIdentifier: String {
    "s2s-\(keyID)"
  }

  /// The public key derived from the stored private key.
  public var publicKey: P256.Signing.PublicKey {
    privateKey.publicKey
  }

  /// Creates an authenticator from a key ID and private key.
  ///
  /// - Parameters:
  ///   - keyID: The key identifier from Apple Developer Console.
  ///   - privateKey: The ECDSA P-256 private key.
  ///   - bodyBufferLimit: Maximum body size to buffer for signing.
  ///     Defaults to 1 MiB.
  /// - Throws: `TokenManagerError.invalidCredentials` if `keyID` is empty
  ///   or shorter than 8 characters. The private key itself is not
  ///   re-validated here — a successfully-constructed `P256.Signing.PrivateKey`
  ///   is, by definition, capable of signing. The convenience initializers
  ///   that take raw data or a PEM string surface parse failures via that
  ///   conversion before reaching this initializer.
  public init(
    keyID: String,
    privateKey: P256.Signing.PrivateKey,
    bodyBufferLimit: Int = ServerToServerAuthenticator.defaultBodyBufferLimit
  ) throws(TokenManagerError) {
    guard !keyID.isEmpty else {
      throw TokenManagerError.invalidCredentials(.keyIdEmpty)
    }
    guard keyID.count >= 8 else {
      throw TokenManagerError.invalidCredentials(.keyIdTooShort)
    }
    self.keyID = keyID
    self.privateKey = privateKey
    self.bodyBufferLimit = bodyBufferLimit
  }

  /// Convenience initializer with raw private key data (32 bytes for P-256).
  public init(
    keyID: String,
    privateKeyData: Data,
    bodyBufferLimit: Int = ServerToServerAuthenticator.defaultBodyBufferLimit
  ) throws(TokenManagerError) {
    let key: P256.Signing.PrivateKey
    do {
      key = try P256.Signing.PrivateKey(rawRepresentation: privateKeyData)
    } catch {
      throw TokenManagerError.invalidCredentials(.privateKeyInvalidOrCorrupted(error))
    }
    try self.init(keyID: keyID, privateKey: key, bodyBufferLimit: bodyBufferLimit)
  }

  /// Convenience initializer with a PEM-encoded private key string.
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  public init(
    keyID: String,
    pemString: String,
    bodyBufferLimit: Int = ServerToServerAuthenticator.defaultBodyBufferLimit
  ) throws(TokenManagerError) {
    let key: P256.Signing.PrivateKey
    do {
      key = try P256.Signing.PrivateKey(pemRepresentation: pemString)
    } catch {
      if error.localizedDescription.contains("PEM")
        || error.localizedDescription.contains("format")
      {
        throw TokenManagerError.invalidCredentials(.invalidPEMFormat(error))
      }
      throw TokenManagerError.invalidCredentials(.privateKeyParseFailed(error))
    }
    try self.init(keyID: keyID, privateKey: key, bodyBufferLimit: bodyBufferLimit)
  }

  /// Reconstructs a `ServerToServerAuthenticator` from data previously
  /// produced by `encoded()`. Re-runs key parse + key-ID validation, so a
  /// corrupted payload throws `TokenManagerError.invalidCredentials`.
  public init(decoding data: Data) throws {
    let wire = try JSONDecoder().decode(WireFormat.self, from: data)
    guard let keyData = Data(base64Encoded: wire.privateKey) else {
      throw TokenManagerError.invalidCredentials(.encodedPayloadInvalidBase64)
    }
    try self.init(
      keyID: wire.keyID,
      privateKeyData: keyData,
      bodyBufferLimit: wire.bodyBufferLimit ?? Self.defaultBodyBufferLimit
    )
  }

  /// Buffers the request body, signs the body + path with the stored private
  /// key, and writes the CloudKit signature headers
  /// (`X-Apple-CloudKit-Request-KeyID`, `…ISO8601Date`, `…SignatureV1`).
  /// The body is reassigned to the buffered copy so downstream middleware
  /// sees the same bytes regardless of `HTTPBody` iteration behavior.
  ///
  /// - Throws: `OpenAPIRuntime` errors when buffering fails or the body
  ///   exceeds `bodyBufferLimit`; crypto errors from `P256.Signing` if
  ///   signing fails.
  public func authenticate(
    request: inout HTTPRequest,
    body: inout HTTPBody?
  ) async throws {
    // Buffer the body so we can both sign it and forward the same bytes.
    // If buffering fails (oversize body, transport error) we propagate the
    // error rather than signing over an empty body and mismatching what the
    // downstream transport actually sends.
    let bodyData = try await Data(buffering: &body, upTo: bodyBufferLimit)

    let signature = try RequestSignature(
      keyID: keyID,
      privateKey: privateKey,
      requestBody: bodyData,
      webServiceSubpath: request.path
    )

    request.headerFields.append(contentsOf: signature.headers)
  }

  /// JSON-encodes the key ID, base64-encoded private key, and
  /// `bodyBufferLimit` for persistence by `TokenStorage`. The output
  /// contains raw P-256 key material — see the protocol-level warning on
  /// `Authenticator.encoded()`.
  public func encoded() throws -> Data {
    let wire = WireFormat(
      keyID: keyID,
      privateKey: privateKey.rawRepresentation.base64EncodedString(),
      bodyBufferLimit: bodyBufferLimit
    )
    return try JSONEncoder().encode(wire)
  }
}

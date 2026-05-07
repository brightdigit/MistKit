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
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public struct ServerToServerAuthenticator: Authenticator {
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

  /// Creates an authenticator from a key ID and private key.
  ///
  /// - Parameters:
  ///   - keyID: The key identifier from Apple Developer Console.
  ///   - privateKey: The ECDSA P-256 private key.
  ///   - bodyBufferLimit: Maximum body size to buffer for signing.
  ///     Defaults to 1 MiB.
  /// - Throws: `TokenManagerError.invalidCredentials` if `keyID` is empty
  ///   or shorter than 8 characters, or if the key fails a test signature.
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
    do {
      _ = try privateKey.signature(for: Data("test".utf8))
    } catch {
      throw TokenManagerError.invalidCredentials(.privateKeyInvalidOrCorrupted(error))
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

  /// The public key derived from the stored private key.
  public var publicKey: P256.Signing.PublicKey {
    privateKey.publicKey
  }

  public func authenticate(
    request: inout HTTPRequest,
    body: inout HTTPBody?
  ) async throws {
    // Buffer the body so we can both sign it and forward the same bytes.
    let bodyData: Data?
    if let original = body {
      do {
        bodyData = try await Data(collecting: original, upTo: bodyBufferLimit)
      } catch {
        bodyData = nil
      }
      if let bytes = bodyData {
        body = HTTPBody(bytes)
      }
    } else {
      bodyData = nil
    }

    let signature = try signRequest(
      requestBody: bodyData,
      webServiceURL: request.path ?? ""
    )

    request.headerFields[.cloudKitRequestKeyID] = signature.keyID
    request.headerFields[.cloudKitRequestISO8601Date] = signature.date
    request.headerFields[.cloudKitRequestSignatureV1] = signature.signature
  }

  /// Signs a CloudKit Web Services request.
  ///
  /// - Parameters:
  ///   - requestBody: The HTTP request body (for POST requests). May be nil.
  ///   - webServiceURL: The CloudKit Web Services URL subpath.
  ///   - date: The request date. Defaults to `Date()`.
  /// - Returns: A `RequestSignature` containing the headers required by
  ///   CloudKit.
  public func signRequest(
    requestBody: Data?,
    webServiceURL: String,
    date: Date = Date()
  ) throws -> RequestSignature {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
    let iso8601Date = formatter.string(from: date)

    let bodyHash: String
    if let requestBody {
      let hash = SHA256.hash(data: requestBody)
      bodyHash = Data(hash).base64EncodedString()
    } else {
      bodyHash = ""
    }

    let payload = "\(iso8601Date):\(bodyHash):\(webServiceURL)"
    let signature = try privateKey.signature(for: Data(payload.utf8))
    return RequestSignature(
      keyID: keyID,
      date: iso8601Date,
      signature: signature.derRepresentation.base64EncodedString()
    )
  }

  public func encoded() throws -> Data {
    let wire = WireFormat(
      keyID: keyID,
      privateKey: privateKey.rawRepresentation.base64EncodedString(),
      bodyBufferLimit: bodyBufferLimit
    )
    return try JSONEncoder().encode(wire)
  }

  public init(decoding data: Data) throws {
    let wire = try JSONDecoder().decode(WireFormat.self, from: data)
    guard let keyData = Data(base64Encoded: wire.privateKey) else {
      throw TokenManagerError.invalidCredentials(
        .privateKeyInvalidOrCorrupted(
          NSError(
            domain: "MistKit.ServerToServerAuthenticator",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Invalid base64 in encoded payload"]
          )
        )
      )
    }
    try self.init(
      keyID: wire.keyID,
      privateKeyData: keyData,
      bodyBufferLimit: wire.bodyBufferLimit ?? Self.defaultBodyBufferLimit
    )
  }

  private struct WireFormat: Codable {
    let keyID: String
    let privateKey: String  // base64-encoded raw representation
    let bodyBufferLimit: Int?
  }
}

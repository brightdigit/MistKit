//
//  RequestSignature.swift
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

/// CloudKit Web Services request signature components
public struct RequestSignature: Sendable {
  /// The key identifier for X-Apple-CloudKit-Request-KeyID header
  public let keyID: String

  /// The ISO8601 date string for X-Apple-CloudKit-Request-ISO8601Date header.
  /// Stored as the exact string that was signed so the wire value cannot drift
  /// from the signed payload.
  public let iso8601DateString: String

  /// The DER-encoded ECDSA signature bytes used for the
  /// X-Apple-CloudKit-Request-SignatureV1 header. Base64-encoded on demand
  /// via `signatureBase64` when building the header value.
  public let signatureDerRepresentation: Data

  /// The base64-encoded signature value for the
  /// X-Apple-CloudKit-Request-SignatureV1 header.
  public var signatureBase64: String {
    signatureDerRepresentation.base64EncodedString()
  }

  /// The CloudKit signature headers in typed form. Merge with
  /// `HTTPRequest.headerFields` via `append(contentsOf:)`.
  public var headers: HTTPFields {
    var fields = HTTPFields()
    fields[.cloudKitRequestKeyID] = keyID
    fields[.cloudKitRequestISO8601Date] = iso8601DateString
    fields[.cloudKitRequestSignatureV1] = signatureBase64
    return fields
  }

  /// Construct a signature from the CloudKit key ID, ISO-8601 date, and DER signature bytes.
  public init(
    keyID: String,
    iso8601DateString: String,
    signatureDerRepresentation: Data
  ) {
    self.keyID = keyID
    self.iso8601DateString = iso8601DateString
    self.signatureDerRepresentation = signatureDerRepresentation
  }
}

extension RequestSignature {
  // Fallback formatter for OSes that predate `Date.ISO8601FormatStyle`.
  // `ISO8601DateFormatter.string(from:)` is documented thread-safe, so a
  // shared instance is safe across concurrent signers.
  nonisolated(unsafe) fileprivate static let legacyISO8601DateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
    return formatter
  }()

  /// Signs a CloudKit Web Services request and produces the headers required
  /// by the server.
  ///
  /// - Parameters:
  ///   - keyID: The CloudKit key identifier from Apple Developer Console.
  ///   - privateKey: The ECDSA P-256 private key used to sign the payload.
  ///   - requestBody: The HTTP request body (for POST requests). May be nil.
  ///   - webServiceSubpath: The CloudKit Web Services URL subpath.
  ///   - date: The request date. Defaults to `Date()`.
  /// - Throws: A `Crypto` error if `P256.Signing.PrivateKey.signature(for:)`
  ///   fails to produce a signature.
  public init(
    keyID: String,
    privateKey: P256.Signing.PrivateKey,
    requestBody: Data?,
    webServiceSubpath: String?,
    date: Date = Date()
  ) throws {
    assert(
      webServiceSubpath != nil,
      "RequestSignature requires a non-nil webServiceSubpath; HTTPRequest.path was nil"
    )
    try self.init(
      keyID: keyID,
      privateKey: privateKey,
      bodyHash: SHA256.cloudKitBodyHash(of: requestBody),
      webServiceSubpath: webServiceSubpath ?? "",
      iso8601DateString: Self.iso8601String(from: date)
    )
  }

  /// Signs a CloudKit Web Services request from pre-computed body hash and
  /// date string. Useful when the caller has already formatted those values
  /// (e.g. for deterministic testing).
  ///
  /// - Parameters:
  ///   - keyID: The CloudKit key identifier from Apple Developer Console.
  ///   - privateKey: The ECDSA P-256 private key used to sign the payload.
  ///   - bodyHash: The base64-encoded SHA-256 hash of the request body, or
  ///     the empty string when no body is present.
  ///   - webServiceSubpath: The CloudKit Web Services URL subpath.
  ///   - iso8601DateString: The ISO8601-formatted request date. This exact
  ///     string is both signed and emitted on the wire — keep them in sync.
  /// - Throws: A `Crypto` error if `P256.Signing.PrivateKey.signature(for:)`
  ///   fails to produce a signature.
  public init(
    keyID: String,
    privateKey: P256.Signing.PrivateKey,
    bodyHash: String,
    webServiceSubpath: String,
    iso8601DateString: String
  ) throws {
    let payload = "\(iso8601DateString):\(bodyHash):\(webServiceSubpath)"
    let signature = try privateKey.signature(for: Data(payload.utf8))

    self.init(
      keyID: keyID,
      iso8601DateString: iso8601DateString,
      signatureDerRepresentation: signature.derRepresentation
    )
  }

  fileprivate static func iso8601String(from date: Date) -> String {
    if #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) {
      return Self.iso8601FormatStyle.format(date)
    }
    return Self.legacyISO8601DateFormatter.string(from: date)
  }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension RequestSignature {
  // Preferred Sendable formatter for modern OSes. Picked up by
  // `iso8601String(from:)` via an `#available` check.
  fileprivate static let iso8601FormatStyle = Date.ISO8601FormatStyle()
}

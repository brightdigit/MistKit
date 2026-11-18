//
//  RequestSignatureBodyHashTests.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//

internal import Crypto
internal import Foundation
internal import HTTPTypes
internal import OpenAPIRuntime
internal import Testing

@testable import MistKit

/// Pins the body hash CloudKit expects in a server-to-server signature,
/// in particular for requests without a body (brightdigit/MistKit#507).
@Suite("RequestSignature body hash", .enabled(if: Platform.isCryptoAvailable))
internal struct RequestSignatureBodyHashTests {
  /// base64(SHA-256 of zero bytes).
  private static let emptyBodyHash = "47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU="

  private static let zonesListPath =
    "/database/1/iCloud.example/development/public/zones/list"

  @Test("A nil body hashes as empty data, not the empty string")
  internal func nilBodyHashesAsEmptyData() {
    #expect(SHA256.cloudKitBodyHash(of: nil) == Self.emptyBodyHash)
  }

  @Test("An empty body hashes the same as a nil body")
  internal func emptyBodyMatchesNilBody() {
    #expect(SHA256.cloudKitBodyHash(of: Data()) == Self.emptyBodyHash)
  }

  @Test("A non-empty body hashes its bytes")
  internal func nonEmptyBodyHashesBytes() {
    // base64(SHA-256("abc"))
    #expect(
      SHA256.cloudKitBodyHash(of: Data("abc".utf8))
        == "ungWv48Bz+pBQUDeXa4iI7ADYaOWF3qctBD/YfIAFa0="
    )
  }

  @Test("A body-less signature signs <date>:<empty-body hash>:<subpath>")
  internal func nilBodySignaturePayload() throws {
    let privateKey = P256.Signing.PrivateKey()
    let signature = try RequestSignature(
      keyID: "test-key-id-12345678",
      privateKey: privateKey,
      requestBody: nil,
      webServiceSubpath: Self.zonesListPath,
      date: Date(timeIntervalSince1970: 0)
    )
    let ecdsa = try P256.Signing.ECDSASignature(
      derRepresentation: signature.signatureDerRepresentation
    )
    let expected = "\(signature.iso8601DateString):\(Self.emptyBodyHash):\(Self.zonesListPath)"
    let oldWrong = "\(signature.iso8601DateString)::\(Self.zonesListPath)"
    #expect(privateKey.publicKey.isValidSignature(ecdsa, for: Data(expected.utf8)))
    #expect(!privateKey.publicKey.isValidSignature(ecdsa, for: Data(oldWrong.utf8)))
  }

  @Test("A GET through the authenticator is signed with the empty-body hash")
  internal func authenticatorSignsGetWithEmptyBodyHash() async throws {
    let privateKey = P256.Signing.PrivateKey()
    let authenticator = try ServerToServerAuthenticator(
      keyID: "test-key-id-12345678",
      privateKey: privateKey
    )
    var request = HTTPRequest(
      method: .get,
      scheme: "https",
      authority: "api.apple-cloudkit.com",
      path: Self.zonesListPath
    )
    var body: HTTPBody?

    try await authenticator.authenticate(request: &request, body: &body)

    let date = try #require(request.headerFields[.cloudKitRequestISO8601Date])
    let signatureBase64 = try #require(request.headerFields[.cloudKitRequestSignatureV1])
    let der = try #require(Data(base64Encoded: signatureBase64))
    let ecdsa = try P256.Signing.ECDSASignature(derRepresentation: der)
    let payload = "\(date):\(Self.emptyBodyHash):\(Self.zonesListPath)"
    #expect(privateKey.publicKey.isValidSignature(ecdsa, for: Data(payload.utf8)))
  }
}

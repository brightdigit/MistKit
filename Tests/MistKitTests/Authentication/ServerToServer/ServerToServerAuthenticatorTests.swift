//
//  ServerToServerAuthenticatorTests.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//

import Crypto
import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

/// Per-authenticator tests for `ServerToServerAuthenticator`.
@Suite("ServerToServerAuthenticator", .enabled(if: Platform.isCryptoAvailable))
internal struct ServerToServerAuthenticatorTests {
  // MARK: - authenticate(request:body:)

  @Test("authenticate adds CloudKit signature headers")
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal func addsSignatureHeaders() async throws {
    let authenticator = try ServerToServerAuthenticator(
      keyID: "test-key-id-12345678",
      privateKey: P256.Signing.PrivateKey()
    )
    var request = HTTPRequest(
      method: .post,
      scheme: "https",
      authority: "api.apple-cloudkit.com",
      path: "/database/1/iCloud.example/development/public/records/query"
    )
    var body: HTTPBody?

    try await authenticator.authenticate(request: &request, body: &body)

    #expect(request.headerFields[.cloudKitRequestKeyID] == "test-key-id-12345678")
    #expect(request.headerFields[.cloudKitRequestISO8601Date] != nil)
    #expect(request.headerFields[.cloudKitRequestSignatureV1] != nil)
  }

  @Test("authenticate buffers body so downstream sees the same bytes")
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal func bufferReplacesSingleIterationBody() async throws {
    let authenticator = try ServerToServerAuthenticator(
      keyID: "test-key-id-12345678",
      privateKey: P256.Signing.PrivateKey()
    )
    var request = HTTPRequest(
      method: .post,
      scheme: "https",
      authority: "api.apple-cloudkit.com",
      path: "/foo"
    )
    let originalBytes = Data("hello-world".utf8)
    // .single iteration behaviour drains after one read. The authenticator
    // must replace `body` with a fresh HTTPBody backed by buffered Data so
    // downstream still receives the bytes.
    var body: HTTPBody? = HTTPBody(originalBytes, length: .known(.init(originalBytes.count)))

    try await authenticator.authenticate(request: &request, body: &body)

    let downstreamBody = try #require(body)
    let downstreamData = try await Data(collecting: downstreamBody, upTo: 1_024)
    #expect(downstreamData == originalBytes)
  }

  // MARK: - init validation

  @Test("init throws on empty key ID")
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal func emptyKeyIDThrows() {
    do {
      _ = try ServerToServerAuthenticator(
        keyID: "",
        privateKey: P256.Signing.PrivateKey()
      )
      Issue.record("Expected init to throw")
    } catch {
      if case .invalidCredentials(.keyIdEmpty) = error {
        // Expected
      } else {
        Issue.record("Unexpected error: \(error)")
      }
    }
  }

  @Test("init throws on key ID shorter than 8 characters")
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal func shortKeyIDThrows() {
    do {
      _ = try ServerToServerAuthenticator(
        keyID: "short",
        privateKey: P256.Signing.PrivateKey()
      )
      Issue.record("Expected init to throw")
    } catch {
      if case .invalidCredentials(.keyIdTooShort) = error {
        // Expected
      } else {
        Issue.record("Unexpected error: \(error)")
      }
    }
  }

  // MARK: - serialization round-trip

  @Test("encoded then init(decoding:) round-trips key + bodyBufferLimit")
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal func encodingRoundTrip() throws {
    let key = P256.Signing.PrivateKey()
    let original = try ServerToServerAuthenticator(
      keyID: "test-key-id-12345678",
      privateKey: key,
      bodyBufferLimit: 2_048
    )
    let data = try original.encoded()
    let restored = try ServerToServerAuthenticator(decoding: data)
    #expect(restored.keyID == original.keyID)
    #expect(restored.privateKey.rawRepresentation == key.rawRepresentation)
    #expect(restored.bodyBufferLimit == 2_048)
  }

  @Test("storageKey is stable")
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal func storageKey() {
    #expect(ServerToServerAuthenticator.storageKey == "server-to-server")
  }

  @Test("defaultStorageIdentifier uses keyID")
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal func defaultStorageIdentifier() throws {
    let authenticator = try ServerToServerAuthenticator(
      keyID: "test-key-id-12345678",
      privateKey: P256.Signing.PrivateKey()
    )
    #expect(authenticator.defaultStorageIdentifier == "s2s-test-key-id-12345678")
  }

  @Test("authenticate throws when body exceeds bodyBufferLimit")
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal func authenticateThrowsOnOversizeBody() async throws {
    let authenticator = try ServerToServerAuthenticator(
      keyID: "test-key-id-12345678",
      privateKey: P256.Signing.PrivateKey(),
      bodyBufferLimit: 16
    )
    var request = HTTPRequest(
      method: .post,
      scheme: "https",
      authority: "api.apple-cloudkit.com",
      path: "/foo"
    )
    let oversized = Data(repeating: 0x41, count: 1_024)
    var body: HTTPBody? = HTTPBody(oversized, length: .known(.init(oversized.count)))

    await #expect(throws: (any Error).self) {
      try await authenticator.authenticate(request: &request, body: &body)
    }
  }
}

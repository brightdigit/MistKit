//
//  WebAuthTokenAuthenticatorTests.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//

import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

/// Per-authenticator tests for `WebAuthTokenAuthenticator`.
@Suite("WebAuthTokenAuthenticator")
internal struct WebAuthTokenAuthenticatorTests {
  // MARK: - authenticate(request:body:)

  @Test("authenticate appends ckAPIToken and ckWebAuthToken query items")
  internal func appendsBothQueryItems() async throws {
    let authenticator = try WebAuthTokenAuthenticator(
      apiToken: TestConstants.apiToken,
      webAuthToken: TestConstants.webAuthToken
    )
    var request = HTTPRequest(
      method: .post,
      scheme: "https",
      authority: "api.apple-cloudkit.com",
      path: "/foo"
    )
    var body: HTTPBody?

    try await authenticator.authenticate(request: &request, body: &body)

    let path = try #require(request.path)
    #expect(path.contains("ckAPIToken=\(TestConstants.apiToken)"))
    #expect(path.contains("ckWebAuthToken="))
  }

  @Test("authenticate character-map-encodes the web auth token")
  internal func encodesWebAuthToken() async throws {
    let webToken = "abc+def/ghi=jkl0123"
    let authenticator = try WebAuthTokenAuthenticator(
      apiToken: TestConstants.apiToken,
      webAuthToken: webToken
    )
    var request = HTTPRequest(
      method: .get,
      scheme: "https",
      authority: "api.apple-cloudkit.com",
      path: "/foo"
    )
    var body: HTTPBody?

    try await authenticator.authenticate(request: &request, body: &body)

    let path = try #require(request.path)
    // The character map encodes + → %2B, / → %2F, = → %3D — but URLComponents
    // additionally percent-encodes the resulting `%` so the query item becomes
    // `%252B` etc. We just assert the raw `+`/`/`/`=` characters do not appear
    // in the encoded value.
    let queryComponents = path.split(separator: "?", maxSplits: 1)
    let query = String(queryComponents.last ?? "")
    let webItem = query.split(separator: "&").first { $0.hasPrefix("ckWebAuthToken=") } ?? ""
    let value = webItem.dropFirst("ckWebAuthToken=".count)
    #expect(!value.contains("+"))
    #expect(!value.contains("/"))
    #expect(!value.contains("="))
  }

  // MARK: - init validation

  @Test("init throws on empty web auth token")
  internal func emptyWebTokenThrows() {
    do {
      _ = try WebAuthTokenAuthenticator(
        apiToken: TestConstants.apiToken,
        webAuthToken: ""
      )
      Issue.record("Expected init to throw")
    } catch let error as TokenManagerError {
      if case .invalidCredentials(.webAuthTokenEmpty) = error {
        // Expected
      } else {
        Issue.record("Unexpected error: \(error)")
      }
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }

  @Test("init throws on web auth token shorter than 10 characters")
  internal func shortWebTokenThrows() {
    do {
      _ = try WebAuthTokenAuthenticator(
        apiToken: TestConstants.apiToken,
        webAuthToken: "tooshort"
      )
      Issue.record("Expected init to throw")
    } catch let error as TokenManagerError {
      if case .invalidCredentials(.webAuthTokenTooShort) = error {
        // Expected
      } else {
        Issue.record("Unexpected error: \(error)")
      }
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }

  // MARK: - serialization round-trip

  @Test("encoded then init(decoding:) round-trips both tokens")
  internal func encodingRoundTrip() throws {
    let original = try WebAuthTokenAuthenticator(
      apiToken: TestConstants.apiToken,
      webAuthToken: TestConstants.webAuthToken
    )
    let data = try original.encoded()
    let restored = try WebAuthTokenAuthenticator(decoding: data)
    #expect(restored.apiToken == original.apiToken)
    #expect(restored.webAuthToken == original.webAuthToken)
  }

  @Test("storageKey is stable")
  internal func storageKey() {
    #expect(WebAuthTokenAuthenticator.storageKey == "web-auth-token")
  }
}

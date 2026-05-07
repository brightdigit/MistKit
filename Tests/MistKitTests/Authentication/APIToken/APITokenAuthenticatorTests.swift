//
//  APITokenAuthenticatorTests.swift
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

/// Per-authenticator tests for `APITokenAuthenticator` — request mutation,
/// format validation in init, and serialization round-trip.
@Suite("APITokenAuthenticator")
internal struct APITokenAuthenticatorTests {
  // MARK: - authenticate(request:body:)

  @Test("authenticate appends ckAPIToken query item")
  internal func appendsAPITokenQueryItem() async throws {
    let authenticator = try APITokenAuthenticator(token: TestConstants.apiToken)
    var request = HTTPRequest(
      method: .get,
      scheme: "https",
      authority: "api.apple-cloudkit.com",
      path: "/database/1/iCloud.com.example/development/public/records/query"
    )
    var body: HTTPBody?

    try await authenticator.authenticate(request: &request, body: &body)

    let path = try #require(request.path)
    #expect(path.contains("ckAPIToken=\(TestConstants.apiToken)"))
  }

  @Test("authenticate preserves existing query items")
  internal func preservesExistingQuery() async throws {
    let authenticator = try APITokenAuthenticator(token: TestConstants.apiToken)
    var request = HTTPRequest(
      method: .get,
      scheme: "https",
      authority: "api.apple-cloudkit.com",
      path: "/foo/bar?existing=value"
    )
    var body: HTTPBody?

    try await authenticator.authenticate(request: &request, body: &body)

    let path = try #require(request.path)
    #expect(path.contains("existing=value"))
    #expect(path.contains("ckAPIToken=\(TestConstants.apiToken)"))
  }

  // MARK: - init validation

  @Test("init throws on empty token")
  internal func emptyTokenThrows() {
    do {
      _ = try APITokenAuthenticator(token: "")
      Issue.record("Expected init to throw")
    } catch let error as TokenManagerError {
      if case .invalidCredentials(.apiTokenEmpty) = error {
        // Expected
      } else {
        Issue.record("Unexpected error: \(error)")
      }
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }

  @Test("init throws on malformed token")
  internal func malformedTokenThrows() {
    do {
      _ = try APITokenAuthenticator(token: "not-a-valid-token")
      Issue.record("Expected init to throw")
    } catch let error as TokenManagerError {
      if case .invalidCredentials(.apiTokenInvalidFormat) = error {
        // Expected
      } else {
        Issue.record("Unexpected error: \(error)")
      }
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }

  // MARK: - serialization round-trip

  @Test("encoded then init(decoding:) round-trips token")
  internal func encodingRoundTrip() throws {
    let original = try APITokenAuthenticator(token: TestConstants.apiToken)
    let data = try original.encoded()
    let restored = try APITokenAuthenticator(decoding: data)
    #expect(restored.token == original.token)
  }

  @Test("storageKey is stable")
  internal func storageKey() {
    #expect(APITokenAuthenticator.storageKey == "api-token")
  }
}

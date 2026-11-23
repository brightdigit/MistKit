//
//  CloudKitServiceTests.VerifyCredentials.swift
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

internal import Foundation
internal import Testing

@testable import MistKit

extension CloudKitServiceTests {
  @Suite(
    "CloudKitService verifyCredentials",
    .enabled(if: Platform.isCryptoAvailable)
  )
  internal struct VerifyCredentials {
    // MARK: - Web auth

    @Test("web auth: users/caller succeeding is accepted")
    internal func webAuthAccepted() async throws {
      let (service, provider) = Self.makeService(
        credentials: try Self.makeCredentials(webAuth: true),
        responses: ["getCaller": Self.reply(200, Recorded.caller)]
      )
      let result = try await service.verifyCredentials()
      #expect(result.webAuth.isAccepted)
      #expect(!result.serverToServer.isConfigured)
      #expect(!result.apiTokenOnly.isConfigured)
      #expect(result.configuredKinds == [.webAuth])
      #expect(result.allAccepted)
      #expect(await provider.callCount(for: "getCaller") == 1)
      #expect(await provider.callCount(for: "listZones") == 0)
    }

    @Test("web auth: an invalid web-auth token (421) is rejected, not 'needs sign-in'")
    internal func webAuthRejected() async throws {
      let (service, _) = Self.makeService(
        credentials: try Self.makeCredentials(webAuth: true),
        responses: ["getCaller": Self.reply(421, Recorded.authenticationRequired)]
      )
      let result = try await service.verifyCredentials()
      guard case .rejected(.authenticationRequired) = result.webAuth else {
        Issue.record("expected rejected(.authenticationRequired), got \(result.webAuth)")
        return
      }
      #expect(!result.allAccepted)
    }

    @Test("web auth: not configured without a web-auth token")
    internal func webAuthNotConfigured() async throws {
      let (service, _) = Self.makeService(
        credentials: try Self.makeCredentials(serverToServer: true),
        responses: ["listZones": Self.reply(200, Recorded.publicZones)]
      )
      let result = try await service.verifyCredentials()
      guard case .notConfigured = result.webAuth else {
        Issue.record("expected notConfigured, got \(result.webAuth)")
        return
      }
    }

    // MARK: - Server-to-server

    @Test("server-to-server: public zones/list succeeding is accepted")
    internal func serverToServerAccepted() async throws {
      let (service, provider) = Self.makeService(
        credentials: try Self.makeCredentials(serverToServer: true),
        responses: ["listZones": Self.reply(200, Recorded.publicZones)]
      )
      let result = try await service.verifyCredentials()
      #expect(result.serverToServer.isAccepted)
      #expect(result.configuredKinds == [.serverToServer])
      #expect(result.allAccepted)
      #expect(await provider.callCount(for: "listZones") == 1)
      #expect(await provider.callCount(for: "getCaller") == 0)
    }

    @Test("server-to-server: AUTHENTICATION_FAILED is rejected")
    internal func serverToServerRejected() async throws {
      let (service, _) = Self.makeService(
        credentials: try Self.makeCredentials(serverToServer: true),
        responses: ["listZones": .authenticationError()]
      )
      let result = try await service.verifyCredentials()
      guard case .rejected(.authenticationFailed) = result.serverToServer else {
        Issue.record("expected rejected(.authenticationFailed), got \(result.serverToServer)")
        return
      }
    }

    @Test("server-to-server: a malformed private key is rejected before sending")
    internal func serverToServerMalformedKey() async throws {
      let (service, provider) = Self.makeService(
        credentials: try Self.makeCredentials(privateKey: .raw("not a PEM")),
        responses: ["listZones": Self.reply(200, Recorded.publicZones)]
      )
      let result = try await service.verifyCredentials()
      #expect(result.serverToServer.error != nil)
      #expect(await provider.callCount(for: "listZones") == 0)
    }

    @Test("server-to-server: not configured without a key")
    internal func serverToServerNotConfigured() async throws {
      let (service, _) = Self.makeService(
        credentials: try Self.makeCredentials(webAuth: true),
        responses: ["getCaller": Self.reply(200, Recorded.caller)]
      )
      let result = try await service.verifyCredentials()
      guard case .notConfigured = result.serverToServer else {
        Issue.record("expected notConfigured, got \(result.serverToServer)")
        return
      }
    }

    // MARK: - API token only

    @Test("API token only: AUTHENTICATION_REQUIRED means valid, needs sign-in")
    internal func apiTokenOnlyAuthenticationRequired() async throws {
      let (service, provider) = Self.makeService(
        credentials: try Self.makeCredentials(apiTokenOnly: true),
        responses: ["getCaller": Self.reply(421, Recorded.authenticationRequired)]
      )
      let result = try await service.verifyCredentials()
      #expect(result.apiTokenOnly.isAccepted)
      #expect(!result.webAuth.isConfigured)
      #expect(result.configuredKinds == [.apiTokenOnly])
      #expect(await provider.callCount(for: "getCaller") == 1)
    }

    @Test("API token only: users/caller succeeding is accepted too")
    internal func apiTokenOnlySucceeded() async throws {
      let (service, _) = Self.makeService(
        credentials: try Self.makeCredentials(apiTokenOnly: true),
        responses: ["getCaller": Self.reply(200, Recorded.caller)]
      )
      let result = try await service.verifyCredentials()
      #expect(result.apiTokenOnly.isAccepted)
    }

    @Test("API token only: a wrong API token (401) is rejected")
    internal func apiTokenOnlyRejected() async throws {
      let (service, _) = Self.makeService(
        credentials: try Self.makeCredentials(apiTokenOnly: true),
        responses: ["getCaller": Self.reply(401, Recorded.apiTokenInvalid)]
      )
      let result = try await service.verifyCredentials()
      guard case .rejected(.authenticationFailed) = result.apiTokenOnly else {
        Issue.record("expected rejected(.authenticationFailed), got \(result.apiTokenOnly)")
        return
      }
    }

    @Test("API token only: not configured when a web-auth token is configured")
    internal func apiTokenOnlyNotConfigured() async throws {
      let (service, provider) = Self.makeService(
        credentials: try Self.makeCredentials(webAuth: true),
        responses: ["getCaller": Self.reply(200, Recorded.caller)]
      )
      let result = try await service.verifyCredentials()
      guard case .notConfigured = result.apiTokenOnly else {
        Issue.record("expected notConfigured, got \(result.apiTokenOnly)")
        return
      }
      #expect(await provider.callCount(for: "getCaller") == 1)
    }
  }
}

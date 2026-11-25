//
//  CloudKitServiceTests.PublicTransport.swift
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

// Deliberately a plain (non-`@testable`) import: these tests must compile
// against MistKit's *public* surface only, the way an app's adapter would.
internal import Foundation
internal import HTTPTypes
internal import MistKit
internal import OpenAPIRuntime
internal import Testing

/// A consumer-side transport written only against public API: it records
/// each request and replays a fixed response body, the way a fixture-replay
/// test or a request-log decorator would.
internal actor ReplayingTransport: ClientTransport {
  internal struct Sent: Sendable {
    internal let operationID: String
    internal let method: HTTPRequest.Method
    internal let path: String?
  }

  private let responseBody: Data
  internal private(set) var sent: [Sent] = []

  internal init(responseBody: Data) {
    self.responseBody = responseBody
  }

  internal func send(
    _ request: HTTPRequest,
    body _: HTTPBody?,
    baseURL _: URL,
    operationID: String
  ) async throws -> (HTTPResponse, HTTPBody?) {
    sent.append(
      Sent(
        operationID: operationID,
        method: request.method,
        path: request.path
      )
    )
    var fields = HTTPFields()
    fields[.contentType] = "application/json"
    return (HTTPResponse(status: .ok, headerFields: fields), HTTPBody(responseBody))
  }
}

extension CloudKitServiceTests {
  /// The transport-accepting initializers are public so a consumer can
  /// replay recorded fixtures or decorate the default transport (e.g. a
  /// request log) without `@testable import MistKit`.
  @Suite("Public Transport Injection", .enabled(if: Platform.isCryptoAvailable))
  internal struct PublicTransport {
    private static let zonesJSON = Data(
      """
      {
        "zones": [
          { "zoneID": { "zoneName": "Tabletop", "ownerRecordName": "_defaultOwner" },
            "atomic": true }
        ]
      }
      """.utf8
    )

    @Test("Credentials initializer routes every request through the injected transport")
    internal func credentialsInitializerUsesInjectedTransport() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let transport = ReplayingTransport(responseBody: Self.zonesJSON)
      let service = CloudKitService(
        containerIdentifier: "iCloud.com.example.Fixture",
        credentials: try Credentials(
          apiAuth: APICredentials(
            apiToken: TestConstants.apiToken,
            webAuthToken: TestConstants.webAuthToken
          )
        ),
        environment: .development,
        transport: transport
      )

      let zones = try await service.listZones(database: .private)

      #expect(zones.map(\.zoneName) == ["Tabletop"])
      #expect(zones.first?.atomic == true)
      let sent = await transport.sent
      #expect(sent.map(\.operationID) == ["listZones"])
      #expect(sent.first?.method == .get)
      let path = try #require(sent.first?.path)
      let expectedPrefix =
        "/database/1/iCloud.com.example.Fixture/development/private/zones/list"
      #expect(path.hasPrefix(expectedPrefix))
      // The transport sees the request after MistKit's auth middleware signed it.
      #expect(path.contains("ckAPIToken="))
      #expect(path.contains("ckWebAuthToken="))
    }

    @Test("TokenManager initializer routes every request through the injected transport")
    internal func tokenManagerInitializerUsesInjectedTransport() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let transport = ReplayingTransport(responseBody: Self.zonesJSON)
      let service = CloudKitService(
        containerIdentifier: "iCloud.com.example.Fixture",
        tokenManager: WebAuthTokenManager(
          apiToken: TestConstants.apiToken,
          webAuthToken: TestConstants.webAuthToken
        ),
        environment: .production,
        transport: transport
      )

      let zones = try await service.listZones(database: .private)

      #expect(zones.map(\.zoneName) == ["Tabletop"])
      let sent = await transport.sent
      #expect(sent.count == 1)
      let path = try #require(sent.first?.path)
      #expect(path.contains("/production/private/zones/list"))
    }
  }
}

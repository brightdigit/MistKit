//
//  CloudKitManagementServiceTests+Request.swift
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
internal import HTTPTypes
internal import Testing

@testable import MistKit

extension CloudKitManagementServiceTests {
  @Suite("Request")
  internal struct Request {
    @Test(
      "Percent-encodes team and container path segments",
      arguments: [
        ("TEAM-1._~", "TEAM-1._~"),
        ("TEAM/1", "TEAM%2F1"),
        ("a b", "a%20b"),
        ("a?b", "a%3Fb"),
        ("a#b", "a%23b"),
        ("a%b", "a%25b"),
        ("a+b", "a%2Bb"),
        ("é", "%C3%A9"),
      ]
    )
    internal func percentEncoding(identifier: String, encoded: String) async throws {
      let transport = RecordingTransport(
        response: ProvisionalManagementFixtures.textResponse("DEFINE SCHEMA")
      )
      let service = CloudKitManagementService(
        teamIdentifier: identifier,
        containerIdentifier: identifier,
        managementToken: ManagementToken("t"),
        transport: transport
      )
      _ = try await service.exportSchemaText(environment: .development)
      let sent = try #require(await transport.sent.first)
      #expect(
        sent.request.path
          == "/v1/database/teams/\(encoded)/containers/\(encoded)"
          + "/environments/DEVELOPMENT/schema/export"
      )
    }

    @Test("Authenticates with the management token header only")
    internal func onlyTokenAuth() async throws {
      let (service, transport) = makeService(
        response: ProvisionalManagementFixtures.textResponse("DEFINE SCHEMA")
      )
      _ = try await service.exportSchemaText(environment: .development)
      let sent = try #require(await transport.sent.first)
      let names = Set(sent.request.headerFields.map(\.name.canonicalName))
      #expect(names == ["x-apple-cloudkit-management-token", "accept"])
      #expect(sent.request.headerFields[.authorization] == nil)
      #expect(sent.request.path?.contains("ckAPIToken") == false)
      #expect(sent.request.path?.contains("?") == false)
    }

    @Test("Sends one request per call, with no caching")
    internal func oneRequestPerCall() async throws {
      let (service, transport) = makeService(
        response: ProvisionalManagementFixtures.textResponse("DEFINE SCHEMA")
      )
      _ = try await service.exportSchemaText(environment: .development)
      #expect(await transport.sent.count == 1)
      _ = try await service.exportSchemaText(environment: .production)
      let paths = await transport.sent.map(\.request.path)
      #expect(paths.count == 2)
      #expect(paths.last??.hasSuffix("/environments/PRODUCTION/schema/export") == true)
    }

    @Test(
      "Spells each environment in upper case",
      arguments: [(Environment.development, "DEVELOPMENT"), (.production, "PRODUCTION")]
    )
    internal func environmentSpelling(environment: Environment, expected: String) {
      #expect(environment.managementEnvironment.rawValue == expected)
    }
  }
}

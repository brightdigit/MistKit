//
//  CloudKitManagementServiceTests+ExportSchema.swift
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
  @Suite("Export schema")
  internal struct ExportSchema {
    @Test(
      "Builds the CKTool JS exportSchema request",
      arguments: [
        (Environment.development, "DEVELOPMENT"),
        (Environment.production, "PRODUCTION"),
      ]
    )
    internal func request(environment: Environment, pathEnvironment: String) async throws {
      let (service, transport) = makeService(
        response: ProvisionalManagementFixtures.textResponse(
          ProvisionalManagementFixtures.exportedSchemaText
        )
      )
      _ = try await service.exportSchemaText(environment: environment)

      let sent = try #require(await transport.sent.first)
      #expect(await transport.sent.count == 1)
      #expect(sent.baseURL == URL(string: "https://api.icloud.apple.com"))
      #expect(sent.request.method == .get)
      #expect(
        sent.request.path
          == "/v1/database/teams/ABCDE12345/containers/iCloud.com.example.Tabletop"
          + "/environments/\(pathEnvironment)/schema/export"
      )
      let tokenHeader = try #require(HTTPField.Name("X-Apple-CloudKit-Management-Token"))
      #expect(sent.request.headerFields[tokenHeader] == "management-token-value")
      #expect(sent.request.headerFields[.accept] == "text/plain")
      #expect(sent.operationID == "exportSchema")
      #expect(sent.body == nil)
    }

    @Test("Percent-encodes path identifiers")
    internal func percentEncoding() async throws {
      let transport = RecordingTransport(
        response: ProvisionalManagementFixtures.textResponse("DEFINE SCHEMA")
      )
      let service = CloudKitManagementService(
        teamIdentifier: "TEAM/1",
        containerIdentifier: "iCloud.com.example.a b",
        managementToken: ManagementToken("t"),
        transport: transport
      )
      _ = try await service.exportSchemaText(environment: .development)
      let sent = try #require(await transport.sent.first)
      #expect(
        sent.request.path
          == "/v1/database/teams/TEAM%2F1/containers/iCloud.com.example.a%20b"
          + "/environments/DEVELOPMENT/schema/export"
      )
    }

    @Test("Returns the raw schema text unchanged")
    internal func rawText() async throws {
      let (service, _) = makeService(
        response: ProvisionalManagementFixtures.textResponse(
          ProvisionalManagementFixtures.exportedSchemaText
        )
      )
      let text = try await service.exportSchemaText(environment: .development)
      #expect(text == ProvisionalManagementFixtures.exportedSchemaText)
    }

    @Test("Parses the export into record types with index flags")
    internal func parsedExport() async throws {
      let (service, _) = makeService(
        response: ProvisionalManagementFixtures.textResponse(
          ProvisionalManagementFixtures.exportedSchemaText
        )
      )
      let exported = try await service.exportSchema(environment: .production)
      #expect(exported.environment == .production)
      #expect(exported.text == ProvisionalManagementFixtures.exportedSchemaText)
      #expect(exported.schema.roles == ["Organizer"])
      #expect(exported.schema.recordTypes.map(\.name) == ["Player", "Match"])

      let player = try #require(exported.schema.recordType(named: "Player"))
      let displayName = try #require(player.field(named: "displayName"))
      #expect(displayName.isQueryable && displayName.isSortable && displayName.isSearchable)
      let country = try #require(player.field(named: "country"))
      #expect(!country.isQueryable && !country.isSortable && !country.isSearchable)

      let match = try #require(exported.schema.recordType(named: "Match"))
      #expect(match.field(named: "players")?.type == SchemaFieldType(.reference, isList: true))
    }

    @Test("A 200 body that isn't valid schema language throws invalidSchema with the text")
    internal func invalidSchema() async throws {
      let (service, _) = makeService(
        response: ProvisionalManagementFixtures.textResponse("not a schema")
      )
      await #expect {
        _ = try await service.exportSchema(environment: .development)
      } throws: { error in
        guard case .invalidSchema(let parseError, let text) = error as? CloudKitManagementError
        else {
          return false
        }
        return parseError.line == 1 && parseError.column == 1 && text == "not a schema"
      }
    }
  }
}

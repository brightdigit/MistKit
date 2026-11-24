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
      "Sends the exportSchema request from management-openapi.yaml",
      arguments: [
        (Environment.development, "DEVELOPMENT"),
        (Environment.production, "PRODUCTION"),
      ]
    )
    internal func request(environment: Environment, pathEnvironment: String) async throws {
      let (service, transport) = makeService(
        response: RecordedManagementFixtures.textResponse(
          RecordedManagementFixtures.exportedSchemaText
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
      #expect(sent.request.headerFields[.accept]?.contains("text/plain") == true)
      #expect(sent.operationID == "exportSchema")
      #expect(sent.body == nil)
    }

    @Test("Returns the raw schema text unchanged")
    internal func rawText() async throws {
      let (service, _) = makeService(
        response: RecordedManagementFixtures.textResponse(
          RecordedManagementFixtures.exportedSchemaText
        )
      )
      let text = try await service.exportSchemaText(environment: .development)
      #expect(text == RecordedManagementFixtures.exportedSchemaText)
    }

    @Test("Parses the export into record types with index flags")
    internal func parsedExport() async throws {
      let (service, _) = makeService(
        response: RecordedManagementFixtures.textResponse(
          RecordedManagementFixtures.exportedSchemaText
        )
      )
      let exported = try await service.exportSchema(environment: .production)
      #expect(exported.environment == .production)
      #expect(exported.text == RecordedManagementFixtures.exportedSchemaText)
      #expect(exported.schema.roles.isEmpty)
      #expect(exported.schema.recordTypes.map(\.name) == ["Note", "Users", "cloudkit.share"])

      let note = try #require(exported.schema.recordType(named: "Note"))
      let title = try #require(note.field(named: "title"))
      #expect(title.isQueryable && title.isSortable && title.isSearchable)
      let modified = try #require(note.field(named: "modified"))
      #expect(modified.isQueryable && !modified.isSortable && !modified.isSearchable)
      #expect(note.field(named: "secret")?.type == SchemaFieldType(.string, isEncrypted: true))
      #expect(note.field(named: "tags")?.type == SchemaFieldType(.string, isList: true))
      let createTime = try #require(note.field(named: "___createTime"))
      #expect(createTime.isSortable && !createTime.isQueryable)
      #expect(
        note.grants.first == SchemaGrant(permissions: [.read, .create, .write], role: "_creator")
      )

      let users = try #require(exported.schema.recordType(named: "Users"))
      #expect(users.field(named: "roles")?.type == SchemaFieldType(.int64, isList: true))
      let share = try #require(exported.schema.recordType(named: "cloudkit.share"))
      #expect(share.field(named: "cloudkit.thumbnailImageData")?.type == SchemaFieldType(.bytes))
    }

    @Test("The recorded export is stored exactly as captured")
    internal func fixtureShape() {
      let text = RecordedManagementFixtures.exportedSchemaText
      #expect(text.hasPrefix("DEFINE SCHEMA\n\n    RECORD TYPE Note (\n"))
      #expect(text.hasSuffix("        GRANT READ TO \"_world\"\n    );\n"))
      #expect(text.utf8.count == 1_675)
    }

    @Test("A 200 body that isn't valid schema language throws invalidSchema with the text")
    internal func invalidSchema() async throws {
      let (service, _) = makeService(
        response: RecordedManagementFixtures.textResponse("not a schema")
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

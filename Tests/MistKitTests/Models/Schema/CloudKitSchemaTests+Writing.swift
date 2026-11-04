//
//  CloudKitSchemaTests+Writing.swift
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

extension CloudKitSchemaTests {
  /// The writer, source lines, strictness and model helpers (MistKit #494).
  @Suite("Writing")
  internal struct Writing {
    private static let schema = CloudKitSchema(
      roles: ["Referee"],
      recordTypes: [
        SchemaRecordType(
          name: "Player",
          fields: [
            SchemaField(
              name: "___recordID",
              type: SchemaFieldType(.reference),
              isQueryable: true
            ),
            SchemaField(
              name: "displayName",
              type: SchemaFieldType(.string),
              isQueryable: true,
              isSortable: true,
              isSearchable: true
            ),
            SchemaField(name: "sortable", type: SchemaFieldType(.int64, isList: true)),
            SchemaField(name: "secret", type: SchemaFieldType(.string, isEncrypted: true)),
            SchemaField(name: "score", type: SchemaFieldType(.number(preferredAs: .double))),
          ],
          grants: [
            SchemaGrant(permissions: [.read], role: "_world"),
            SchemaGrant(permissions: [.read, .write], role: "Referee"),
          ]
        )
      ]
    )

    private static let expectedText =
      [
        "DEFINE SCHEMA",
        "",
        "    CREATE ROLE Referee;",
        "",
        "    RECORD TYPE Player (",
        "        \"___recordID\"  REFERENCE QUERYABLE,",
        "        displayName    STRING QUERYABLE SEARCHABLE SORTABLE,",
        "        \"sortable\"     LIST<INT64>,",
        "        secret         ENCRYPTED STRING,",
        "        score          NUMBER PREFERRED AS DOUBLE,",
        "        GRANT READ TO \"_world\",",
        "        GRANT READ, WRITE TO Referee",
        "    );",
      ].joined(separator: "\n") + "\n"

    @Test("writes the cktool layout and reads back to an equal schema")
    internal func roundTrip() throws {
      #expect(Self.schema.schemaText == Self.expectedText)
      #expect(try CloudKitSchema(parsing: Self.schema.schemaText) == Self.schema)
    }

    @Test("parsing and annotating record each declaration's line")
    internal func sourceLines() throws {
      let parsed = try CloudKitSchema(parsing: Self.expectedText)
      let player = try #require(parsed.recordType(named: "Player"))
      #expect(player.sourceLine == 5)
      #expect(player.fields.map(\.sourceLine) == [6, 7, 8, 9, 10])
      let annotated = Self.schema.annotatingSourceLines()
      #expect(annotated.recordTypes.first?.sourceLine == 5)
      #expect(annotated.recordTypes.first?.field(named: "score")?.sourceLine == 10)
    }

    @Test("names are quoted when they must be")
    internal func quoting() {
      #expect(CloudKitSchema.writtenIdentifier("Player") == "Player")
      #expect(CloudKitSchema.writtenIdentifier("_world") == "\"_world\"")
      #expect(CloudKitSchema.writtenIdentifier("grant") == "\"grant\"")
      #expect(CloudKitSchema.writtenIdentifier("first name") == "\"first name\"")
      #expect(CloudKitSchema.writtenIdentifier("2fa") == "\"2fa\"")
    }

    @Test(
      "strict about bare system names, reserved words, duplicates and ENCRYPTED",
      arguments: [
        (
          "DEFINE SCHEMA\n RECORD TYPE A (___recordID REFERENCE);",
          2, 17, "names starting with \"_\" are system names and must be quoted"
        ),
        (
          "DEFINE SCHEMA\n RECORD TYPE A (sortable STRING);",
          2, 17, "\"sortable\" is a reserved word; quote it to use it as a name"
        ),
        (
          "DEFINE SCHEMA\n RECORD TYPE A (a STRING, a INT64);",
          2, 27, "field \"a\" is already defined in A"
        ),
        (
          "DEFINE SCHEMA\n RECORD TYPE A ();\n RECORD TYPE A ();",
          3, 14, "record type \"A\" is already defined"
        ),
        (
          "DEFINE SCHEMA\n RECORD TYPE A (photo ENCRYPTED ASSET);",
          2, 33, "ASSET can't be ENCRYPTED"
        ),
        (
          "DEFINE SCHEMA\n RECORD TYPE A (name STRING INDEXED);",
          2, 29, "unknown field option \"INDEXED\""
        ),
        (
          "DEFINE SCHEMA\n RECORD TYPE A (name STRING",
          2, 28, "expected \",\" or \")\", found the end of the file"
        ),
      ]
    )
    internal func strictness(source: String, line: Int, column: Int, message: String) {
      #expect(throws: SchemaParseError(line: line, column: column, message: message)) {
        try CloudKitSchema(parsing: source)
      }
    }

    @Test("a missing ; after the last declaration is tolerated")
    internal func missingFinalSemicolon() throws {
      let schema = try CloudKitSchema(parsing: "DEFINE SCHEMA\n RECORD TYPE A (name STRING)")
      #expect(schema.recordTypes.map(\.name) == ["A"])
    }

    @Test("implicit system fields fill in what the schema doesn't list")
    internal func implicitFields() throws {
      let player = try #require(Self.schema.recordType(named: "Player"))
      let names = player.fieldsIncludingImplicit.map(\.name)
      #expect(
        names.prefix(5)
          == ["___createTime", "___createdBy", "___etag", "___modTime", "___modifiedBy"]
      )
      #expect(names.filter { $0 == "___recordID" }.count == 1)
      let recordID = player.fieldsIncludingImplicit.first { $0.name == "___recordID" }
      #expect(recordID?.isQueryable == true)
    }

    @Test("canBeEncrypted per primitive")
    internal func encryptable() {
      #expect(SchemaPrimitiveType.string.canBeEncrypted)
      #expect(SchemaPrimitiveType.location.canBeEncrypted)
      #expect(!SchemaPrimitiveType.asset.canBeEncrypted)
      #expect(!SchemaPrimitiveType.reference.canBeEncrypted)
      #expect(!SchemaPrimitiveType.number(preferredAs: nil).canBeEncrypted)
    }

    @Test("the models are Codable")
    internal func codable() throws {
      let data = try JSONEncoder().encode(Self.schema)
      #expect(try JSONDecoder().decode(CloudKitSchema.self, from: data) == Self.schema)
    }
  }
}

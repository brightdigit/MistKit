//
//  CloudKitSchemaTests+WriterGolden.swift
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
  @Suite("Writer golden")
  internal struct WriterGolden {
    private static let schema = CloudKitSchema(
      roles: ["Moderator", "_support"],
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
            SchemaField(name: "tags", type: SchemaFieldType(.string, isList: true)),
            SchemaField(name: "pin", type: SchemaFieldType(.int64, isEncrypted: true)),
            SchemaField(name: "legacy", type: SchemaFieldType(.number(preferredAs: .double))),
            SchemaField(
              name: "grant",
              type: SchemaFieldType(.bytes, isEncrypted: true, isList: true)
            ),
          ],
          grants: [
            SchemaGrant(permissions: [.read, .write], role: "Moderator"),
            SchemaGrant(permissions: [.read], role: "_world"),
          ]
        ),
        SchemaRecordType(name: "Empty"),
      ]
    )

    // Lines, not a multi-line literal: the writer's four-space indents trip
    // SwiftLint's indentation rule inside string literals.
    private static let expected =
      [
        "DEFINE SCHEMA",
        "",
        "    CREATE ROLE Moderator;",
        "",
        "    CREATE ROLE \"_support\";",
        "",
        "    RECORD TYPE Player (",
        "        \"___recordID\"  REFERENCE QUERYABLE,",
        "        displayName    STRING QUERYABLE SEARCHABLE SORTABLE,",
        "        tags           LIST<STRING>,",
        "        pin            ENCRYPTED INT64,",
        "        legacy         NUMBER PREFERRED AS DOUBLE,",
        "        \"grant\"        LIST<ENCRYPTED BYTES>,",
        "        GRANT READ, WRITE TO Moderator,",
        "        GRANT READ TO \"_world\"",
        "    );",
        "",
        "    RECORD TYPE Empty (",
        "    );",
        "",
      ].joined(separator: "\n")

    @Test("writes aligned fields, canonical index order and quoted names")
    internal func golden() {
      #expect(Self.schema.schemaText == Self.expected)
    }

    @Test("annotating finds the line of each record type and field")
    internal func lines() throws {
      let annotated = Self.schema.annotatingSourceLines()
      let player = try #require(annotated.recordType(named: "Player"))
      #expect(player.sourceLine == 7)
      #expect(player.field(named: "displayName")?.sourceLine == 9)
      #expect(annotated.recordType(named: "Empty")?.sourceLine == 18)
    }

    @Test("what it writes parses back to the same schema")
    internal func roundTrip() throws {
      #expect(try CloudKitSchema(parsing: Self.schema.schemaText) == Self.schema)
    }
  }
}

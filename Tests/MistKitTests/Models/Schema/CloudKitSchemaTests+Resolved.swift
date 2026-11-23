//
//  CloudKitSchemaTests+Resolved.swift
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
  @Suite("Resolved field types")
  internal struct Resolved {
    @Test("ENCRYPTED is dropped and NUMBER takes its preferred type, or DOUBLE")
    internal func resolvedTypes() throws {
      let schema = try CloudKitSchema(
        parsing: """
          DEFINE SCHEMA RECORD TYPE Vault (
            pin ENCRYPTED INT64, legacy NUMBER, units NUMBER PREFERRED AS INT64,
            ratio NUMBER PREFERRED AS DOUBLE, tags LIST<ENCRYPTED STRING>,
            friends LIST<REFERENCE>, seen TIMESTAMP, home LOCATION
          );
          """
      )
      let vault = try #require(schema.recordType(named: "Vault"))
      #expect(
        vault.fields.map(\.resolvedType) == [
          .int64, .double, .int64, .double, .list(.string), .list(.reference), .timestamp,
          .location,
        ]
      )
    }

    @Test(
      "every primitive resolves to its own type",
      arguments: [
        (SchemaPrimitiveType.asset, FieldType.asset),
        (.bytes, .bytes),
        (.double, .double),
        (.int64, .int64),
        (.location, .location),
        (.reference, .reference),
        (.string, .string),
        (.timestamp, .timestamp),
      ]
    )
    internal func primitives(primitive: SchemaPrimitiveType, expected: FieldType) {
      #expect(SchemaFieldType(primitive).resolved == expected)
      #expect(SchemaFieldType(primitive, isList: true).resolved == .list(expected))
      #expect(SchemaFieldType(expected) == SchemaFieldType(primitive))
      #expect(SchemaFieldType(.list(expected)) == SchemaFieldType(primitive, isList: true))
    }

    @Test("a nested list keeps its innermost element type")
    internal func nestedList() {
      #expect(
        SchemaFieldType(.list(.list(.int64))) == SchemaFieldType(.int64, isList: true)
      )
    }

    @Test("isList and elementType")
    internal func listHelpers() {
      #expect(FieldType.list(.string).isList)
      #expect(!FieldType.string.isList)
      #expect(FieldType.list(.asset).elementType == .asset)
      #expect(FieldType.location.elementType == .location)
    }

    @Test("a value reports its type; an empty list keeps its element type")
    internal func valueTypes() {
      let values: [(FieldValue, FieldType)] = [
        (.string(.value("a")), .string),
        (.int64(.value(1)), .int64),
        (.double(.value(1.5)), .double),
        (.bytes(.value(Data())), .bytes),
        (.date(.value(Date(timeIntervalSince1970: 0))), .timestamp),
        (.location(.value(Location(latitude: 0, longitude: 0))), .location),
        (.reference(.value(Reference(recordName: "r"))), .reference),
        (.asset(.list([])), .list(.asset)),
        (.string(.list([])), .list(.string)),
        (.int64(.list([1, 2])), .list(.int64)),
      ]
      for (value, type) in values {
        #expect(value.fieldType == type)
      }
    }

    @Test("fields and record types are identified by name")
    internal func identifiers() {
      let field = SchemaField(name: "title", type: SchemaFieldType(.string))
      #expect(field.id == "title")
      #expect(SchemaRecordType(name: "Note", fields: [field]).id == "Note")
    }

    @Test("FieldType is Codable")
    internal func codable() throws {
      let types: [FieldType] = [.string, .list(.reference), .timestamp]
      let data = try JSONEncoder().encode(types)
      #expect(try JSONDecoder().decode([FieldType].self, from: data) == types)
    }
  }
}

//
//  CloudKitSchemaTests+Fixtures.swift
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
  @Suite("Mistico fixtures")
  internal struct Fixtures {
    @Test(
      "parse → write → parse gives the same schema, and writing is stable",
      arguments: [SchemaFixtures.everything, SchemaFixtures.recordedExport]
    )
    internal func roundTrip(_ text: String) throws {
      let schema = try CloudKitSchema(parsing: text)
      let written = schema.schemaText
      #expect(try CloudKitSchema(parsing: written) == schema)
      #expect(try CloudKitSchema(parsing: written).schemaText == written)
    }

    @Test("everything.ckdb parses every construct")
    internal func everything() throws {
      let schema = try CloudKitSchema(parsing: SchemaFixtures.everything)
      #expect(schema.roles == ["Moderator", "Support_Team"])
      #expect(schema.recordTypes.map(\.name) == ["Inventory", "grant", "Empty"])
      let inventory = try #require(schema.recordType(named: "Inventory"))
      #expect(inventory.fields.count == 29)
      let quantity = try #require(inventory.field(named: "quantity"))
      #expect(quantity.isQueryable && quantity.isSortable && !quantity.isSearchable)
      #expect(
        inventory.field(named: "secretTags")?.type
          == SchemaFieldType(.string, isEncrypted: true, isList: true)
      )
      #expect(
        inventory.grants.first
          == SchemaGrant(permissions: [.read, .create, .write], role: "Moderator")
      )
    }

    @Test("the malformed fixture fails at line 9, column 26")
    internal func malformed() {
      #expect {
        _ = try CloudKitSchema(parsing: SchemaFixtures.malformed)
      } throws: { error in
        guard let error = error as? SchemaParseError else {
          return false
        }
        return error.line == 9 && error.column == 26
          && error.message == "expected a data type, found \"QUERYABLE\""
      }
    }

    @Test("the recorded export lists its record types in order")
    internal func recordedExport() throws {
      let schema = try CloudKitSchema(parsing: SchemaFixtures.recordedExport)
      #expect(
        schema.recordTypes.map(\.name)
          == ["Feedback", "Match", "Player", "Tournament", "Users"]
      )
      #expect(schema.roles.isEmpty)
    }

    @Test("the recorded export cut off mid-record-type doesn't parse")
    internal func recordedMalformed() {
      #expect(throws: SchemaParseError.self) {
        try CloudKitSchema(parsing: SchemaFixtures.recordedMalformed)
      }
    }
  }
}

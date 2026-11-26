//
//  CloudKitSchemaTests+Lexical.swift
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
  @Suite("Lexical")
  internal struct Lexical {
    @Test("Comments in all three forms are ignored")
    internal func comments() throws {
      let schema = try CloudKitSchema(
        parsing: """
          // leading comment
          DEFINE SCHEMA
          /* a
            multi-line comment; with RECORD TYPE inside */
          RECORD TYPE Feed (
            -- dash comment
            "feedURL" STRING QUERYABLE, // trailing comment
            title STRING
          );
          """
      )
      #expect(schema.recordTypes.map(\.name) == ["Feed"])
      #expect(schema.recordType(named: "Feed")?.fields.map(\.name) == ["feedURL", "title"])
    }

    @Test("CRLF line endings end line comments and count lines")
    internal func crlfLineEndings() throws {
      let text = [
        "DEFINE SCHEMA -- comment",
        "RECORD TYPE T ( // comment",
        "  f STRING QUERYABLE",
        ");",
      ]
      .joined(separator: "\r\n")
      let schema = try CloudKitSchema(parsing: text)
      #expect(schema.recordType(named: "T")?.field(named: "f")?.isQueryable == true)

      #expect {
        _ = try CloudKitSchema(parsing: "DEFINE SCHEMA\r\nRECORD TYPE T ( f WIDGET );")
      } throws: { error in
        (error as? SchemaParseError).map { $0.line == 2 && $0.column == 19 } ?? false
      }
    }

    @Test("Keywords are case-insensitive")
    internal func caseInsensitiveKeywords() throws {
      let schema = try CloudKitSchema(
        parsing: "define schema record type T ( f string queryable, grant read to \"_world\" );"
      )
      let type = try #require(schema.recordType(named: "T"))
      #expect(type.field(named: "f")?.type == SchemaFieldType(.string))
      #expect(type.field(named: "f")?.isQueryable == true)
      #expect(type.grants == [SchemaGrant(permissions: [.read], role: "_world")])
    }
  }
}

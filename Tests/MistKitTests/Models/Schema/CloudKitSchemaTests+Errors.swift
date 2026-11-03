//
//  CloudKitSchemaTests+Errors.swift
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
  @Suite("Parse errors")
  internal struct Errors {
    @Test(
      "Malformed schemas throw SchemaParseError with a position",
      arguments: [
        // Missing DEFINE SCHEMA.
        ("RECORD TYPE T ( f STRING );", 1, 1),
        // Unknown data type.
        ("DEFINE SCHEMA RECORD TYPE T ( f WIDGET );", 1, 33),
        // Unterminated record type.
        ("DEFINE SCHEMA RECORD TYPE T ( f STRING", 1, 39),
        // Unknown field option.
        ("DEFINE SCHEMA\nRECORD TYPE T ( f STRING UNIQUE );", 2, 26),
        // Unterminated quoted identifier.
        ("DEFINE SCHEMA RECORD TYPE \"T ( f STRING );", 1, 27),
        // Unterminated block comment.
        ("DEFINE SCHEMA /* never closed", 1, 15),
        // Missing semicolon between record types.
        ("DEFINE SCHEMA RECORD TYPE A ( f STRING ) RECORD TYPE B ( g STRING );", 1, 42),
        // Unknown permission.
        ("DEFINE SCHEMA RECORD TYPE T ( GRANT DELETE TO \"_world\" );", 1, 37),
      ]
    )
    internal func malformed(source: String, line: Int, column: Int) {
      #expect {
        _ = try CloudKitSchema(parsing: source)
      } throws: { error in
        guard let parseError = error as? SchemaParseError else {
          return false
        }
        return parseError.line == line && parseError.column == column
      }
    }

    @Test("A parse error describes itself with its line and column")
    internal func description() throws {
      let error = SchemaParseError(line: 3, column: 7, message: "expected a data type")
      #expect(error.errorDescription == "Schema line 3, column 7: expected a data type")
    }
  }
}

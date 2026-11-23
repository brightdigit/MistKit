//
//  SchemaParseErrorCase.swift
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

/// A malformed schema, and where and why parsing it should fail.
internal struct SchemaParseErrorCase: Sendable, CustomTestStringConvertible {
  internal let text: String
  internal let line: Int
  internal let column: Int
  internal let message: String

  internal var testDescription: String { message }
}

extension SchemaParseErrorCase {
  internal static let all: [Self] = [
    Self(
      text: "RECORD TYPE A ();",
      line: 1,
      column: 1,
      message: "expected DEFINE, found \"RECORD\""
    ),
    Self(
      text: "DEFINE SCHEMA\n  RECORD TYPE A (\n    name ,\n  );",
      line: 3,
      column: 10,
      message: "expected a data type, found \",\""
    ),
    Self(
      text: "DEFINE SCHEMA\n  RECORD TYPE A (\n    name TEXT\n  );",
      line: 3,
      column: 10,
      message: "expected a data type, found \"TEXT\""
    ),
    Self(
      text: "DEFINE SCHEMA\n RECORD TYPE A (name STRING INDEXED);",
      line: 2,
      column: 29,
      message: "unknown field option \"INDEXED\""
    ),
    Self(
      text: "DEFINE SCHEMA\n RECORD TYPE A (a STRING, a INT64);",
      line: 2,
      column: 27,
      message: "field \"a\" is already defined in A"
    ),
    Self(
      text: "DEFINE SCHEMA\n RECORD TYPE A ();\n RECORD TYPE A ();",
      line: 3,
      column: 14,
      message: "record type \"A\" is already defined"
    ),
    Self(
      text: "DEFINE SCHEMA\n RECORD TYPE A (photo ENCRYPTED ASSET);",
      line: 2,
      column: 33,
      message: "ASSET can't be ENCRYPTED"
    ),
    Self(
      text: "DEFINE SCHEMA\n RECORD TYPE A (GRANT DELETE TO \"_world\");",
      line: 2,
      column: 23,
      message: "expected READ, CREATE or WRITE, found \"DELETE\""
    ),
    Self(
      text: "DEFINE SCHEMA\n RECORD TYPE A (tags LIST<STRING);",
      line: 2,
      column: 33,
      message: "expected \">\", found \")\""
    ),
    Self(
      text: "DEFINE SCHEMA\n RECORD TYPE A (n NUMBER PREFERRED AS STRING);",
      line: 2,
      column: 39,
      message: "expected INT64 or DOUBLE, found \"STRING\""
    ),
    Self(
      text: "DEFINE SCHEMA\n RECORD TYPE A (___recordID REFERENCE);",
      line: 2,
      column: 17,
      message: "names starting with \"_\" are system names and must be quoted"
    ),
    Self(
      text: "DEFINE SCHEMA\n RECORD TYPE A (sortable STRING);",
      line: 2,
      column: 17,
      message: "\"sortable\" is a reserved word; quote it to use it as a name"
    ),
    Self(
      text: "DEFINE SCHEMA\n RECORD TYPE A (name STRING)\n RECORD TYPE B ();",
      line: 3,
      column: 2,
      message: "expected \";\", found \"RECORD\""
    ),
    Self(
      text: "DEFINE SCHEMA\n RECORD TYPE A (name STRING",
      line: 2,
      column: 28,
      message: "expected \",\" or \")\", found the end of the file"
    ),
    Self(
      text: "DEFINE SCHEMA\n RECORD TYPE \"A (name STRING);",
      line: 2,
      column: 14,
      message: "unterminated quoted identifier"
    ),
    Self(
      text: "DEFINE SCHEMA\n /* never closed\n RECORD TYPE A ();",
      line: 2,
      column: 2,
      message: "unterminated /* comment"
    ),
    Self(
      text: "DEFINE SCHEMA\n RECORD TYPE A (name STRING) @;",
      line: 2,
      column: 30,
      message: "unexpected character \"@\""
    ),
  ]
}

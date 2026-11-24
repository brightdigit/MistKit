//
//  CKDBHighlighter.swift
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

/// Splits a line of CloudKit Schema Language (`.ckdb`) into runs, so
/// types and keywords can be coloured.
///
/// Never changes the text: the runs join back to the line.
public enum CKDBHighlighter {
  /// What a run is.
  public enum Kind: Hashable, Sendable {
    /// Names, punctuation and spacing.
    case plain
    /// A data type: `STRING`, `INT64`, `LIST`, ….
    case type
    /// A keyword: `RECORD TYPE`, `QUERYABLE`, `GRANT`, ….
    case keyword
    /// A `//` comment to the end of the line.
    case comment
  }

  /// One run of text.
  public struct Token: Hashable, Sendable {
    /// The text.
    public let text: String
    /// What it is.
    public let kind: Kind
  }

  private static let types: Set<String> = [
    "STRING", "INT64", "DOUBLE", "NUMBER", "TIMESTAMP", "BYTES", "REFERENCE", "ASSET",
    "LOCATION", "LIST",
  ]
  private static let keywords: Set<String> = [
    "DEFINE", "SCHEMA", "RECORD", "TYPE", "CREATE", "ROLE", "GRANT", "TO", "READ",
    "WRITE",
    "QUERYABLE", "SORTABLE", "SEARCHABLE", "ENCRYPTED", "PREFERRED", "AS",
  ]

  /// The runs in one line.
  public static func tokens(in line: String) -> [Token] {
    var tokens: [Token] = []
    var rest = Substring(line)
    while !rest.isEmpty {
      if rest.hasPrefix("//") {
        tokens.append(Token(text: String(rest), kind: .comment))
        break
      }
      if rest.first == "\"" {
        let end =
          rest.dropFirst().firstIndex(of: "\"").map { rest.index(after: $0) }
          ?? rest.endIndex
        tokens.append(Token(text: String(rest[..<end]), kind: .plain))
        rest = rest[end...]
        continue
      }
      let isWord = rest.first.map(isWordCharacter) ?? false
      let end =
        rest.firstIndex { isWordCharacter($0) != isWord || $0 == "\"" }
        ?? rest.endIndex
      let text = String(rest[..<end])
      tokens.append(Token(text: text, kind: isWord ? kind(of: text) : .plain))
      rest = rest[end...]
    }
    return tokens
  }

  private static func kind(of word: String) -> Kind {
    if types.contains(word) {
      return .type
    }
    return keywords.contains(word) ? .keyword : .plain
  }

  private static func isWordCharacter(_ character: Character) -> Bool {
    character.isLetter || character.isNumber || character == "_"
  }
}

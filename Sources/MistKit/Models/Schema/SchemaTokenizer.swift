//
//  SchemaTokenizer.swift
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

/// Splits CloudKit Schema Language text into ``SchemaToken``s.
///
/// Skips whitespace and the three comment forms the language allows
/// (`// …`, `-- …`, `/* … */`).
internal struct SchemaTokenizer {
  private static let symbols: Set<Character> = ["(", ")", ",", ";", "<", ">"]

  private let characters: [Character]
  private var index = 0
  private var line = 1
  private var column = 1

  internal init(text: String) {
    self.characters = Array(text)
  }

  private static func isWordCharacter(_ character: Character) -> Bool {
    character == "_" || (character.isASCII && (character.isLetter || character.isNumber))
  }

  /// Every token in the text, ending with a single `.end` token.
  internal mutating func tokenize() throws -> [SchemaToken] {
    var tokens: [SchemaToken] = []
    while true {
      try skipTrivia()
      let token = try nextToken()
      tokens.append(token)
      if token.kind == .end {
        return tokens
      }
    }
  }

  private func peek(_ offset: Int = 0) -> Character? {
    let position = index + offset
    return position < characters.count ? characters[position] : nil
  }

  private mutating func advance() {
    // `isNewline`, not `== "\n"`: Swift reads "\r\n" as one Character.
    if characters[index].isNewline {
      line += 1
      column = 1
    } else {
      column += 1
    }
    index += 1
  }

  private mutating func skipTrivia() throws {
    while let character = peek() {
      if character.isWhitespace {
        advance()
      } else if (character == "/" && peek(1) == "/") || (character == "-" && peek(1) == "-") {
        while let next = peek(), !next.isNewline {
          advance()
        }
      } else if character == "/" && peek(1) == "*" {
        try skipBlockComment()
      } else {
        return
      }
    }
  }

  private mutating func skipBlockComment() throws {
    let startLine = line
    let startColumn = column
    advance()
    advance()
    while let character = peek() {
      if character == "*" && peek(1) == "/" {
        advance()
        advance()
        return
      }
      advance()
    }
    throw SchemaParseError(
      line: startLine,
      column: startColumn,
      message: "unterminated /* comment"
    )
  }

  private mutating func nextToken() throws -> SchemaToken {
    let startLine = line
    let startColumn = column
    guard let character = peek() else {
      return SchemaToken(kind: .end, line: startLine, column: startColumn)
    }
    if Self.symbols.contains(character) {
      advance()
      return SchemaToken(kind: .symbol(character), line: startLine, column: startColumn)
    }
    if character == "\"" {
      return try quotedIdentifier(line: startLine, column: startColumn)
    }
    if Self.isWordCharacter(character) {
      var word = ""
      while let next = peek(), Self.isWordCharacter(next) {
        word.append(next)
        advance()
      }
      return SchemaToken(kind: .word(word), line: startLine, column: startColumn)
    }
    throw SchemaParseError(
      line: startLine,
      column: startColumn,
      message: "unexpected character '\(character)'"
    )
  }

  private mutating func quotedIdentifier(line startLine: Int, column startColumn: Int) throws
    -> SchemaToken
  {
    advance()
    var name = ""
    while let character = peek() {
      if character == "\"" {
        advance()
        return SchemaToken(kind: .quoted(name), line: startLine, column: startColumn)
      }
      if character.isNewline {
        break
      }
      name.append(character)
      advance()
    }
    throw SchemaParseError(
      line: startLine,
      column: startColumn,
      message: "unterminated quoted identifier"
    )
  }
}

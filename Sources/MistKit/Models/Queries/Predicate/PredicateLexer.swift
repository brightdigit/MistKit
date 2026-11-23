//
//  PredicateLexer.swift
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

/// Splits predicate text into tokens, skipping whitespace and `/* … */`
/// comments.
///
/// Written by hand, without `Regex`, so it runs on every platform MistKit
/// supports.
internal struct PredicateLexer {
  private static let distanceFunction = Array("distanceToLocation:fromLocation:")

  internal let characters: [Character]
  internal var offset = 0

  internal init(_ text: String) {
    characters = Array(text)
  }

  internal static func isIdentifierStart(_ character: Character) -> Bool {
    character == "_" || (character.isLetter && character.isASCII)
  }

  /// Every token, ending with ``PredicateTokenKind/end``.
  internal mutating func tokens() throws(PredicateSyntaxError) -> [PredicateToken] {
    var tokens: [PredicateToken] = []
    while let token = try nextToken() {
      tokens.append(token)
    }
    tokens.append(PredicateToken(.end, characters.count..<characters.count))
    return tokens
  }

  internal func peek(_ distance: Int = 0) -> Character? {
    let index = offset + distance
    return index < characters.count ? characters[index] : nil
  }

  internal mutating func identifier() -> String {
    let start = offset
    while let character = peek(),
      Self.isIdentifierStart(character) || character.isASCIIDigit
    {
      offset += 1
    }
    return String(characters[start..<offset])
  }

  private mutating func nextToken() throws(PredicateSyntaxError) -> PredicateToken? {
    try skipTrivia()
    guard let character = peek() else {
      return nil
    }
    let start = offset
    if character == "\"" || character == "'" {
      return try string(quote: character)
    }
    if character.isASCIIDigit || (character == "-" && peek(1)?.isASCIIDigit == true) {
      return number()
    }
    if Self.isIdentifierStart(character) {
      return word()
    }
    if character == "#", let next = peek(1), Self.isIdentifierStart(next) {
      offset += 1
      let name = identifier()
      return PredicateToken(.escapedField(name), start..<offset)
    }
    if character == "%" || character == "$" {
      throw placeholder()
    }
    return try symbol()
  }

  /// `%@`, `%K` or `$name`: a format placeholder, not a value.
  private mutating func placeholder() -> PredicateSyntaxError {
    let start = offset
    offset += 1
    _ = identifier()
    if offset == start + 1, peek() != nil {
      offset += 1
    }
    return PredicateSyntaxError(
      .placeholder(String(characters[start..<offset])),
      start..<offset
    )
  }

  private mutating func word() -> PredicateToken {
    let start = offset
    if characters[offset...].starts(with: Self.distanceFunction) {
      offset += Self.distanceFunction.count
      return PredicateToken(.distanceFunction, start..<offset)
    }
    return PredicateToken(.word(identifier()), start..<offset)
  }

  private mutating func symbol() throws(PredicateSyntaxError) -> PredicateToken {
    let start = offset
    for symbol in PredicateKeywords.symbols
    where characters[offset...].starts(with: Array(symbol)) {
      offset += symbol.count
      return PredicateToken(.symbol(symbol), start..<offset)
    }
    throw PredicateSyntaxError(.unexpectedCharacter(characters[start]), start..<(start + 1))
  }

  private mutating func skipTrivia() throws(PredicateSyntaxError) {
    while let character = peek() {
      if character.isWhitespace {
        offset += 1
      } else if character == "/", peek(1) == "*" {
        try skipComment()
      } else {
        return
      }
    }
  }

  private mutating func skipComment() throws(PredicateSyntaxError) {
    let start = offset
    offset += 2
    while offset < characters.count {
      if peek() == "*", peek(1) == "/" {
        offset += 2
        return
      }
      offset += 1
    }
    throw PredicateSyntaxError(.unterminatedComment, start..<characters.count)
  }
}

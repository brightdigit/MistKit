//
//  SchemaParser+Tokens.swift
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

extension SchemaParser {
  internal mutating func advance() {
    if current.kind != .end {
      position += 1
    }
  }

  internal mutating func consumeKeyword(_ keyword: String) -> Bool {
    guard current.isKeyword(keyword) else {
      return false
    }
    advance()
    return true
  }

  internal mutating func consumeSymbol(_ symbol: Character) -> Bool {
    guard current.kind == .symbol(symbol) else {
      return false
    }
    advance()
    return true
  }

  internal mutating func expectKeyword(_ keyword: String) throws {
    guard consumeKeyword(keyword) else {
      throw unexpected(expecting: keyword)
    }
  }

  internal mutating func expectSymbol(_ symbol: Character) throws {
    guard consumeSymbol(symbol) else {
      throw unexpected(expecting: "\"\(symbol)\"")
    }
  }

  /// A name: a quoted identifier, or a bare one that isn't reserved and
  /// doesn't start with an underscore.
  internal mutating func identifier(describing what: String) throws -> (
    name: String, token: SchemaToken
  ) {
    let token = current
    switch token.kind {
    case .quoted(let name):
      advance()
      return (name, token)
    case .word(let word):
      if Self.reservedWords.contains(word.uppercased()) {
        throw SchemaParseError(
          at: token,
          message: "\"\(word)\" is a reserved word; quote it to use it as a name"
        )
      }
      if word.hasPrefix("_") {
        throw SchemaParseError(
          at: token,
          message: "names starting with \"_\" are system names and must be quoted"
        )
      }
      advance()
      return (word, token)
    case .symbol, .end:
      throw unexpected(expecting: what)
    }
  }

  /// "expected X, found Y" at the current token.
  internal func unexpected(expecting expected: String) -> SchemaParseError {
    SchemaParseError(at: current, message: "expected \(expected), found \(current.displayName)")
  }
}

extension SchemaParseError {
  internal init(at token: SchemaToken, message: String) {
    self.init(line: token.line, column: token.column, message: message)
  }
}

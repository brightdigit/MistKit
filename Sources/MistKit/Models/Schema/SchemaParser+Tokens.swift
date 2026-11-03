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

  internal func isSymbol(_ symbol: Character) -> Bool {
    current.kind == .symbol(symbol)
  }

  internal func peekNext() -> SchemaToken {
    tokens[min(position + 1, tokens.count - 1)]
  }

  internal func nextIsPermission() -> Bool {
    guard case .word(let word) = peekNext().kind else {
      return false
    }
    return SchemaPermission(rawValue: word.uppercased()) != nil
  }

  internal mutating func expectKeyword(_ keyword: String) throws {
    guard current.isKeyword(keyword) else {
      throw unexpected(expecting: keyword)
    }
    advance()
  }

  internal mutating func expectSymbol(_ symbol: Character) throws {
    guard isSymbol(symbol) else {
      throw unexpected(expecting: "'\(symbol)'")
    }
    advance()
  }

  internal mutating func identifier(describing what: String) throws -> String {
    switch current.kind {
    case .word(let name), .quoted(let name):
      advance()
      return name
    case .symbol, .end:
      throw unexpected(expecting: what)
    }
  }

  internal func unexpected(expecting expected: String) -> SchemaParseError {
    SchemaParseError(
      line: current.line,
      column: current.column,
      message: "expected \(expected), found \(current.displayName)"
    )
  }
}

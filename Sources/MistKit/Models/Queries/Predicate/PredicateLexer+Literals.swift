//
//  PredicateLexer+Literals.swift
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

extension PredicateLexer {
  private static func unescape(_ character: Character) -> Character {
    switch character {
    case "n": "\n"
    case "r": "\r"
    case "t": "\t"
    default: character
    }
  }

  /// A quoted string; `\"`, `\'`, `\\`, `\n`, `\r` and `\t` are escapes.
  internal mutating func string(
    quote: Character
  ) throws(PredicateSyntaxError) -> PredicateToken {
    let start = offset
    offset += 1
    var value = ""
    while let character = peek() {
      offset += 1
      if character == quote {
        return PredicateToken(.string(value), start..<offset)
      }
      if character == "\\", let escaped = peek() {
        offset += 1
        value.append(Self.unescape(escaped))
      } else {
        value.append(character)
      }
    }
    throw PredicateSyntaxError(.unterminatedString, start..<characters.count)
  }

  /// `-12`, `2.5`, `1e-05`.
  internal mutating func number() -> PredicateToken {
    let start = offset
    if peek() == "-" {
      offset += 1
    }
    skipDigits()
    if peek() == ".", peek(1)?.isASCIIDigit == true {
      offset += 1
      skipDigits()
    }
    if peek() == "e" || peek() == "E" {
      let sign = peek(1) == "+" || peek(1) == "-" ? 1 : 0
      if peek(1 + sign)?.isASCIIDigit == true {
        offset += 1 + sign
        skipDigits()
      }
    }
    return PredicateToken(.number(String(characters[start..<offset])), start..<offset)
  }

  private mutating func skipDigits() {
    while peek()?.isASCIIDigit == true {
      offset += 1
    }
  }
}

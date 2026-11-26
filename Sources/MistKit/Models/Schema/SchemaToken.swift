//
//  SchemaToken.swift
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

/// One lexical token of CloudKit Schema Language.
internal struct SchemaToken: Sendable, Equatable {
  internal enum Kind: Sendable, Equatable {
    /// A bare word: a keyword or an unquoted identifier.
    case word(String)
    /// A double-quoted identifier, without its quotes.
    case quoted(String)
    /// One of `(` `)` `,` `;` `<` `>`.
    case symbol(Character)
    /// The end of the text.
    case end
  }

  internal let kind: Kind
  internal let line: Int
  internal let column: Int

  /// How the token reads in an error message, such as `"RECORD"`.
  internal var displayName: String {
    switch kind {
    case .word(let word): "\"\(word)\""
    case .quoted(let name): "'\"\(name)\"'"
    case .symbol(let symbol): "\"\(symbol)\""
    case .end: "the end of the file"
    }
  }

  /// The word, uppercased, when this is a bare word.
  internal var keyword: String? {
    if case .word(let word) = kind {
      return word.uppercased()
    }
    return nil
  }

  /// Whether this is a bare word matching `keyword` case-insensitively.
  ///
  /// Quoted identifiers are never keywords; that's how the language lets a
  /// schema use reserved words as names.
  internal func isKeyword(_ keyword: String) -> Bool {
    guard case .word(let word) = kind else {
      return false
    }
    return word.caseInsensitiveCompare(keyword) == .orderedSame
  }
}

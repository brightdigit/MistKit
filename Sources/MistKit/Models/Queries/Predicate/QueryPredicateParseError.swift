//
//  QueryPredicateParseError.swift
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

public import Foundation

/// A predicate format string ``QueryPredicate`` can't read, with where.
public struct QueryPredicateParseError: LocalizedError, Hashable, Sendable {
  /// What went wrong.
  public let reason: Reason
  /// The offending text, in `Character` offsets; empty at the end of input.
  public let range: Range<Int>
  /// The 1-based line of the start of ``range``.
  public let line: Int
  /// The 1-based column, in `Character`s, of the start of ``range``.
  public let column: Int

  /// The `Character` offset of the start of ``range``.
  public var offset: Int { range.lowerBound }

  /// A description of the error with its position.
  public var errorDescription: String? {
    "Predicate line \(line), column \(column): \(reason.message)"
  }

  /// Creates an error.
  /// - Parameters:
  ///   - reason: What went wrong.
  ///   - range: The offending text, in `Character` offsets.
  ///   - line: The 1-based line of the start of `range`.
  ///   - column: The 1-based column of the start of `range`.
  public init(reason: Reason, range: Range<Int>, line: Int, column: Int) {
    self.reason = reason
    self.range = range
    self.line = line
    self.column = column
  }

  /// Creates an error, finding the line and column of `range` in `text`.
  /// - Parameters:
  ///   - reason: What went wrong.
  ///   - range: The offending text, in `Character` offsets.
  ///   - text: The format string `range` is in.
  public init(reason: Reason, range: Range<Int>, in text: String) {
    var line = 1
    var column = 1
    for character in text.prefix(range.lowerBound) {
      if character.isNewline {
        line += 1
        column = 1
      } else {
        column += 1
      }
    }
    self.init(reason: reason, range: range, line: line, column: column)
  }

  private static func utf16Offset(ofCharacter offset: Int, in text: String) -> Int {
    let index = text.index(text.startIndex, offsetBy: offset, limitedBy: text.endIndex)
    return text.utf16.distance(from: text.startIndex, to: index ?? text.endIndex)
  }

  /// ``range`` in UTF-16 code units, as `NSRange` and text views count.
  /// - Parameter text: The format string the error is in.
  /// - Returns: The range in UTF-16 offsets.
  public func utf16Range(in text: String) -> Range<Int> {
    let lower = Self.utf16Offset(ofCharacter: range.lowerBound, in: text)
    let upper = Self.utf16Offset(ofCharacter: range.upperBound, in: text)
    return lower..<upper
  }
}

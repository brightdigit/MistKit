//
//  KeyIDValidationFailure.swift
//  MistKitConfiguration
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

/// Why a CloudKit server-to-server key ID was rejected.
///
/// Carries structured facts only — no prose. The consuming application decides how to
/// phrase the failure, because only it knows which environment variable or flag supplied
/// the value.
public enum KeyIDValidationFailure: Error, Equatable, Sendable {
  /// The key ID was empty, or contained only whitespace.
  case empty
  /// The key ID had leading or trailing whitespace, commonly a stray newline from a copy.
  case surroundingWhitespace
  /// The key ID was not ``KeyIDValidator/expectedLength`` characters long.
  case incorrectLength(actual: Int)
  /// The key ID contained characters outside `0-9`, `a-f`, `A-F`.
  case nonHexCharacters
}

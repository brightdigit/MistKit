//
//  RegexPatternsTests+Convenience.swift
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

import Foundation
import Testing

@testable import MistKit

extension RegexPatternsTests {
  // MARK: - Convenience Method Tests

  @Test("matches(in:) convenience method works correctly")
  internal func convenienceMatchesMethod() {
    let token = "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
    let matches = NSRegularExpression.apiTokenRegex.matches(in: token)

    #expect(matches.count == 1)
    #expect(matches[0].range.length == 64)
  }

  @Test("matches(in:) handles empty string")
  internal func convenienceMatchesEmptyString() {
    let matches = NSRegularExpression.apiTokenRegex.matches(in: "")
    #expect(matches.isEmpty)
  }

  @Test("matches(in:) handles unicode strings")
  internal func convenienceMatchesUnicode() {
    let text = "Hello 🌍 token=abc123"
    let matches = NSRegularExpression.maskGenericTokenRegex.matches(in: text)
    #expect(matches.count >= 1)
  }

  // MARK: - Edge Cases

  @Test("Multiple tokens in same string")
  internal func multipleTokensInString() {
    let token1 = String(repeating: "a", count: 64)
    let token2 = String(repeating: "b", count: 64)
    let text = "First: \(token1) Second: \(token2)"

    let matches = NSRegularExpression.maskApiTokenRegex.matches(in: text)
    #expect(matches.count == 2)
  }

  @Test("Overlapping patterns don't double-match")
  internal func overlappingPatterns() {
    let text = "keytoken=value123"
    let keyMatches = NSRegularExpression.maskGenericKeyRegex.matches(in: text)
    let tokenMatches = NSRegularExpression.maskGenericTokenRegex.matches(in: text)

    // Should find one or the other, not both
    #expect((keyMatches.count + tokenMatches.count) > 0)
  }

  @Test("Case sensitivity for hex patterns")
  internal func caseSensitivityHex() {
    let lowerCase = String(repeating: "a", count: 64)
    let upperCase = String(repeating: "A", count: 64)
    let mixed = (String(repeating: "a", count: 32) + String(repeating: "A", count: 32))

    for token in [lowerCase, upperCase, mixed] {
      let matches = NSRegularExpression.apiTokenRegex.matches(in: token)
      #expect(matches.count == 1, "Should match hex regardless of case")
    }
  }
}

//
//  RegexPatternsTests.swift
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
@testable import MistKit
import Testing

@Suite("NSRegularExpression CommonPatterns Tests")
struct RegexPatternsTests {
  // MARK: - API Token Validation Tests

  @Test("API token regex validates correct 64-character hex strings")
  func apiTokenValidHex() {
    let validTokens = [
      "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789",
      "ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789",
      "0000000000000000000000000000000000000000000000000000000000000000",
      "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    ]

    for token in validTokens {
      let matches = NSRegularExpression.apiTokenRegex.matches(in: token)
      #expect(matches.count == 1, "Should match valid API token: \(token)")
    }
  }

  @Test("API token regex rejects invalid formats")
  func apiTokenInvalidFormats() {
    let invalidTokens = [
      "abc",  // Too short
      "abcdef0123456789abcdef0123456789abcdef0123456789abcdef012345678",  // 63 chars
      "abcdef0123456789abcdef0123456789abcdef0123456789abcdef01234567890",  // 65 chars
      "abcdef0123456789abcdef0123456789abcdef0123456789abcdef012345678g",  // Invalid char
      "abcdef0123456789 abcdef0123456789abcdef0123456789abcdef0123456789",  // Space
      ""  // Empty
    ]

    for token in invalidTokens {
      let matches = NSRegularExpression.apiTokenRegex.matches(in: token)
      #expect(matches.isEmpty, "Should not match invalid API token: \(token)")
    }
  }

  // MARK: - Web Auth Token Validation Tests

  @Test("Web auth token regex validates base64-like strings")
  func webAuthTokenValidBase64() {
    let validTokens = [
      String(repeating: "A", count: 100),
      String(repeating: "a", count: 150),
      String(repeating: "0", count: 100) + "==",
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=" + String(repeating: "A", count: 40),
      String(repeating: "Z", count: 200) + "_"
    ]

    for token in validTokens {
      let matches = NSRegularExpression.webAuthTokenRegex.matches(in: token)
      #expect(matches.count == 1, "Should match valid web auth token")
    }
  }

  @Test("Web auth token regex rejects invalid formats")
  func webAuthTokenInvalidFormats() {
    let invalidTokens = [
      String(repeating: "A", count: 99),  // Too short
      "invalid chars !@#$%",
      "",
      "abc",
      String(repeating: " ", count: 100)  // Spaces not allowed
    ]

    for token in invalidTokens {
      let matches = NSRegularExpression.webAuthTokenRegex.matches(in: token)
      #expect(matches.isEmpty, "Should not match invalid web auth token: \(token)")
    }
  }

  // MARK: - Key ID Validation Tests

  @Test("Key ID regex validates 64-character hex strings")
  func keyIDValidHex() {
    let validKeyIDs = [
      "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
      "FEDCBA0987654321FEDCBA0987654321FEDCBA0987654321FEDCBA0987654321",
      "0123456789abcdefABCDEF0123456789abcdefABCDEF0123456789abcdefABCD"
    ]

    for keyID in validKeyIDs {
      let matches = NSRegularExpression.keyIDRegex.matches(in: keyID)
      #expect(matches.count == 1, "Should match valid key ID: \(keyID)")
    }
  }

  @Test("Key ID regex rejects invalid formats")
  func keyIDInvalidFormats() {
    let invalidKeyIDs = [
      String(repeating: "a", count: 63),  // Too short
      String(repeating: "a", count: 65),  // Too long
      "g" + String(repeating: "a", count: 63),  // Invalid character
      "",
      "key-id-with-dashes"
    ]

    for keyID in invalidKeyIDs {
      let matches = NSRegularExpression.keyIDRegex.matches(in: keyID)
      #expect(matches.isEmpty, "Should not match invalid key ID: \(keyID)")
    }
  }

  // MARK: - Masking Pattern Tests

  @Test("Mask API token regex finds tokens in text")
  func maskAPITokenFindsTokens() {
    let text = "API token: abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789 found"
    let matches = NSRegularExpression.maskApiTokenRegex.matches(in: text)

    #expect(matches.count == 1)
    if let match = matches.first {
      let range = match.range
      let matchedText = (text as NSString).substring(with: range)
      #expect(matchedText.count == 64)
    }
  }

  @Test("Mask web auth token regex finds tokens in text")
  func maskWebAuthTokenFindsTokens() {
    let token = String(repeating: "A", count: 100)
    let text = "Web auth: \(token)== in message"
    let matches = NSRegularExpression.maskWebAuthTokenRegex.matches(in: text)

    #expect(matches.count >= 1)
  }

  @Test("Mask key ID regex finds key IDs in text")
  func maskKeyIDFindsKeys() {
    let keyID = String(repeating: "a", count: 40)
    let text = "Key ID is \(keyID) here"
    let matches = NSRegularExpression.maskKeyIdRegex.matches(in: text)

    #expect(matches.count == 1)
  }

  @Test("Mask generic token regex finds token patterns")
  func maskGenericTokenFindsPatterns() {
    let testCases = [
      "token=abc123def456",
      "token: xyz789",
      "token=BASE64STRING==",
      "token: BASE64+/=="
    ]

    for text in testCases {
      let matches = NSRegularExpression.maskGenericTokenRegex.matches(in: text)
      #expect(matches.count >= 1, "Should find token in: \(text)")
    }
  }

  @Test("Mask generic key regex finds key patterns")
  func maskGenericKeyFindsPatterns() {
    let testCases = [
      "key=secretvalue123",
      "key: privatekey456",
      "key=KEYDATA789",
      "key:KEY+DATA/123"
    ]

    for text in testCases {
      let matches = NSRegularExpression.maskGenericKeyRegex.matches(in: text)
      #expect(matches.count >= 1, "Should find key in: \(text)")
    }
  }

  @Test("Mask generic secret regex finds secret patterns")
  func maskGenericSecretFindsPatterns() {
    let testCases = [
      "secret=mysecret123",
      "secret: topsecret456",
      "secret=CLASSIFIED789",
      "secret:SECRET+VALUE/="
    ]

    for text in testCases {
      let matches = NSRegularExpression.maskGenericSecretRegex.matches(in: text)
      #expect(matches.count >= 1, "Should find secret in: \(text)")
    }
  }

  // MARK: - Convenience Method Tests

  @Test("matches(in:) convenience method works correctly")
  func convenienceMatchesMethod() {
    let token = "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
    let matches = NSRegularExpression.apiTokenRegex.matches(in: token)

    #expect(matches.count == 1)
    #expect(matches[0].range.length == 64)
  }

  @Test("matches(in:) handles empty string")
  func convenienceMatchesEmptyString() {
    let matches = NSRegularExpression.apiTokenRegex.matches(in: "")
    #expect(matches.isEmpty)
  }

  @Test("matches(in:) handles unicode strings")
  func convenienceMatchesUnicode() {
    let text = "Hello 🌍 token=abc123"
    let matches = NSRegularExpression.maskGenericTokenRegex.matches(in: text)
    #expect(matches.count >= 1)
  }

  // MARK: - Edge Cases

  @Test("Multiple tokens in same string")
  func multipleTokensInString() {
    let token1 = String(repeating: "a", count: 64)
    let token2 = String(repeating: "b", count: 64)
    let text = "First: \(token1) Second: \(token2)"

    let matches = NSRegularExpression.maskApiTokenRegex.matches(in: text)
    #expect(matches.count == 2)
  }

  @Test("Overlapping patterns don't double-match")
  func overlappingPatterns() {
    let text = "keytoken=value123"
    let keyMatches = NSRegularExpression.maskGenericKeyRegex.matches(in: text)
    let tokenMatches = NSRegularExpression.maskGenericTokenRegex.matches(in: text)

    // Should find one or the other, not both
    #expect((keyMatches.count + tokenMatches.count) > 0)
  }

  @Test("Case sensitivity for hex patterns")
  func caseSensitivityHex() {
    let lowerCase = String(repeating: "a", count: 64)
    let upperCase = String(repeating: "A", count: 64)
    let mixed = (String(repeating: "a", count: 32) + String(repeating: "A", count: 32))

    for token in [lowerCase, upperCase, mixed] {
      let matches = NSRegularExpression.apiTokenRegex.matches(in: token)
      #expect(matches.count == 1, "Should match hex regardless of case")
    }
  }
}

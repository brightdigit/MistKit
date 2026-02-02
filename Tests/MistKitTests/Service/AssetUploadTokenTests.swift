//
//  AssetUploadTokenTests.swift
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

@Suite("AssetUploadToken Model Tests")
internal struct AssetUploadTokenTests {
  @Test("AssetUploadToken initializes with all fields")
  internal func assetUploadTokenInitializesWithAllFields() {
    let token = AssetUploadToken(
      url: "https://cvws.icloud-content.com/test-url",
      recordName: "test-record",
      fieldName: "testField"
    )

    #expect(token.url == "https://cvws.icloud-content.com/test-url")
    #expect(token.recordName == "test-record")
    #expect(token.fieldName == "testField")
  }

  @Test("AssetUploadToken initializes with nil optional fields")
  internal func assetUploadTokenInitializesWithNilOptionalFields() {
    let token = AssetUploadToken(
      url: nil,
      recordName: nil,
      fieldName: nil
    )

    #expect(token.url == nil)
    #expect(token.recordName == nil)
    #expect(token.fieldName == nil)
  }

  @Test("AssetUploadToken supports equality comparison")
  internal func assetUploadTokenSupportsEqualityComparison() {
    let token1 = AssetUploadToken(
      url: "https://example.com/test",
      recordName: "record1",
      fieldName: "field1"
    )

    let token2 = AssetUploadToken(
      url: "https://example.com/test",
      recordName: "record1",
      fieldName: "field1"
    )

    let token3 = AssetUploadToken(
      url: "https://example.com/different",
      recordName: "record1",
      fieldName: "field1"
    )

    #expect(token1 == token2, "Tokens with same values should be equal")
    #expect(token1 != token3, "Tokens with different URLs should not be equal")
  }

  @Test("AssetUploadResult initializes with tokens")
  internal func assetUploadResultInitializesWithTokens() {
    let tokens = [
      AssetUploadToken(url: "url1", recordName: "record1", fieldName: "field1"),
      AssetUploadToken(url: "url2", recordName: "record2", fieldName: "field2")
    ]

    let result = AssetUploadResult(tokens: tokens)

    #expect(result.tokens.count == 2)
    #expect(result.tokens[0].url == "url1")
    #expect(result.tokens[1].url == "url2")
  }

  @Test("AssetUploadResult handles empty token array")
  internal func assetUploadResultHandlesEmptyTokenArray() {
    let result = AssetUploadResult(tokens: [])

    #expect(result.tokens.isEmpty)
    #expect(result.tokens.count == 0)
  }
}

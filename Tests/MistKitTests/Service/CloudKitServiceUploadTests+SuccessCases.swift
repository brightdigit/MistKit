//
//  CloudKitServiceUploadTests+SuccessCases.swift
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

extension CloudKitServiceUploadTests {
  @Suite("Success Cases")
  internal struct SuccessCases {
    @Test("uploadAssets() successfully uploads valid asset")
    internal func uploadAssetsSuccessfullyUploadsValidAsset() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceUploadTests.makeSuccessfulUploadService(tokenCount: 1)
      let testData = Data(count: 1024)  // 1 KB of test data

      let result = try await service.uploadAssets(data: testData)

      #expect(result.tokens.count == 1, "Should receive exactly one upload token")
      #expect(result.tokens[0].url != nil, "Upload token should have a URL")
      #expect(result.tokens[0].recordName != nil, "Upload token should have a record name")
      #expect(result.tokens[0].fieldName != nil, "Upload token should have a field name")
    }

    @Test("uploadAssets() parses single token from response")
    internal func uploadAssetsParseSingleToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceUploadTests.makeSuccessfulUploadService(tokenCount: 1)
      let testData = Data(count: 2048)

      let result = try await service.uploadAssets(data: testData)

      #expect(result.tokens.count == 1)
      let token = result.tokens[0]
      #expect(token.url?.contains("test-token-0") == true)
      #expect(token.recordName == "test-record-0")
      #expect(token.fieldName == "file")
    }

    @Test("uploadAssets() parses multiple tokens from response")
    internal func uploadAssetsParseMultipleTokens() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceUploadTests.makeSuccessfulUploadService(tokenCount: 3)
      let testData = Data(count: 4096)

      let result = try await service.uploadAssets(data: testData)

      #expect(result.tokens.count == 3, "Should receive three upload tokens")

      // Verify each token has the expected fields
      for (index, token) in result.tokens.enumerated() {
        #expect(token.url?.contains("test-token-\(index)") == true)
        #expect(token.recordName == "test-record-\(index)")
        #expect(token.fieldName == "file")
      }
    }
  }
}

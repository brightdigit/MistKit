//
//  CelestraErrorTests+RecoverySuggestion.swift
//  CelestraCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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
import MistKit
import Testing

@testable import CelestraCloudKit

extension CelestraErrorTests {
  // MARK: - Recovery Suggestion Tests

  @Test("Quota exceeded has recovery suggestion")
  internal func testQuotaExceededRecoverySuggestion() {
    let error = CelestraError.quotaExceeded

    #expect(error.recoverySuggestion != nil)
    #expect(error.recoverySuggestion?.contains("Wait") == true)
    #expect(error.recoverySuggestion?.contains("quota") == true)
  }

  @Test("Network unavailable has recovery suggestion")
  internal func testNetworkUnavailableRecoverySuggestion() {
    let error = CelestraError.networkUnavailable

    #expect(error.recoverySuggestion != nil)
    #expect(error.recoverySuggestion?.contains("connection") == true)
  }

  @Test("RSS fetch failed has recovery suggestion")
  internal func testRSSFetchFailedRecoverySuggestion() throws {
    let url = try #require(URL(string: "https://example.com/feed.xml"))
    let underlyingError = NSError(domain: "Test", code: 1)
    let error = CelestraError.rssFetchFailed(url, underlying: underlyingError)

    #expect(error.recoverySuggestion != nil)
    #expect(error.recoverySuggestion?.contains("feed URL") == true)
  }

  @Test("Permission denied has recovery suggestion")
  internal func testPermissionDeniedRecoverySuggestion() {
    let error = CelestraError.permissionDenied

    #expect(error.recoverySuggestion != nil)
    #expect(error.recoverySuggestion?.contains("permissions") == true)
  }

  @Test("Invalid feed data has recovery suggestion")
  internal func testInvalidFeedDataRecoverySuggestion() {
    let error = CelestraError.invalidFeedData("Invalid XML")

    #expect(error.recoverySuggestion != nil)
    #expect(error.recoverySuggestion?.contains("RSS") == true)
  }

  @Test("Record not found has no recovery suggestion")
  internal func testRecordNotFoundNoRecoverySuggestion() {
    let error = CelestraError.recordNotFound("feed-123")

    #expect(error.recoverySuggestion == nil)
  }

  @Test("CloudKit error has no recovery suggestion")
  internal func testCloudKitErrorNoRecoverySuggestion() {
    let ckError = CloudKitError.httpError(statusCode: 500)
    let error = CelestraError.cloudKitError(ckError)

    #expect(error.recoverySuggestion == nil)
  }
}

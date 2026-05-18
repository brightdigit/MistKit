//
//  CelestraErrorTests+Description.swift
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

internal import Foundation
internal import MistKit
internal import Testing

@testable import CelestraCloudKit

extension CelestraErrorTests {
  // MARK: - Error Description Tests

  @Test("Quota exceeded has description")
  internal func testQuotaExceededDescription() {
    let error = CelestraError.quotaExceeded

    #expect(error.errorDescription?.contains("quota") == true)
    #expect(error.errorDescription?.contains("exceeded") == true)
  }

  @Test("Network unavailable has description")
  internal func testNetworkUnavailableDescription() {
    let error = CelestraError.networkUnavailable

    #expect(error.errorDescription?.contains("Network") == true)
    #expect(error.errorDescription?.contains("unavailable") == true)
  }

  @Test("Permission denied has description")
  internal func testPermissionDeniedDescription() {
    let error = CelestraError.permissionDenied

    #expect(error.errorDescription?.contains("Permission") == true)
    #expect(error.errorDescription?.contains("denied") == true)
  }

  @Test("Invalid feed data includes reason")
  internal func testInvalidFeedDataDescription() {
    let error = CelestraError.invalidFeedData("Malformed XML")

    #expect(error.errorDescription?.contains("Invalid feed data") == true)
    #expect(error.errorDescription?.contains("Malformed XML") == true)
  }

  @Test("Record not found includes record name")
  internal func testRecordNotFoundDescription() {
    let error = CelestraError.recordNotFound("feed-abc123")

    #expect(error.errorDescription?.contains("Record not found") == true)
    #expect(error.errorDescription?.contains("feed-abc123") == true)
  }

  @Test("RSS fetch failed includes URL")
  internal func testRSSFetchFailedDescription() throws {
    let url = try #require(URL(string: "https://example.com/feed.xml"))
    let underlyingError = NSError(
      domain: "Test",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Connection timeout"]
    )
    let error = CelestraError.rssFetchFailed(url, underlying: underlyingError)

    #expect(error.errorDescription?.contains("example.com/feed.xml") == true)
    #expect(error.errorDescription?.contains("Failed to fetch") == true)
  }

  @Test("Batch operation failed includes error count")
  internal func testBatchOperationFailedDescription() {
    let errors: [any Error] = [
      NSError(domain: "Test", code: 1),
      NSError(domain: "Test", code: 2),
      NSError(domain: "Test", code: 3),
    ]
    let error = CelestraError.batchOperationFailed(errors)

    #expect(error.errorDescription?.contains("3") == true)
    #expect(error.errorDescription?.contains("Batch operation failed") == true)
  }
}

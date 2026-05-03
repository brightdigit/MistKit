//
//  CelestraErrorTests.swift
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

@Suite("CelestraError Tests")
internal struct CelestraErrorTests {
  // MARK: - Retriability Tests

  @Test("Network unavailable is retriable")
  internal func testNetworkUnavailableRetriable() {
    let error = CelestraError.networkUnavailable
    #expect(error.isRetriable == true)
  }

  @Test("RSS fetch failed is retriable")
  internal func testRSSFetchFailedRetriable() throws {
    let url = try #require(URL(string: "https://example.com/feed.xml"))
    let underlyingError = NSError(domain: "Test", code: 1)
    let error = CelestraError.rssFetchFailed(url, underlying: underlyingError)

    #expect(error.isRetriable == true)
  }

  @Test("Quota exceeded is not retriable")
  internal func testQuotaExceededNotRetriable() {
    let error = CelestraError.quotaExceeded
    #expect(error.isRetriable == false)
  }

  @Test("Permission denied is not retriable")
  internal func testPermissionDeniedNotRetriable() {
    let error = CelestraError.permissionDenied
    #expect(error.isRetriable == false)
  }

  @Test("Invalid feed data is not retriable")
  internal func testInvalidFeedDataNotRetriable() {
    let error = CelestraError.invalidFeedData("Malformed XML")
    #expect(error.isRetriable == false)
  }

  @Test("Record not found is not retriable")
  internal func testRecordNotFoundNotRetriable() {
    let error = CelestraError.recordNotFound("feed-123")
    #expect(error.isRetriable == false)
  }

  @Test("CloudKit 5xx errors are retriable")
  internal func testCloudKit5xxRetriable() {
    let ckError = CloudKitError.httpError(statusCode: 500)
    let error = CelestraError.cloudKitError(ckError)

    #expect(error.isRetriable == true)
  }

  @Test("CloudKit 503 error is retriable")
  internal func testCloudKit503Retriable() {
    let ckError = CloudKitError.httpError(statusCode: 503)
    let error = CelestraError.cloudKitError(ckError)

    #expect(error.isRetriable == true)
  }

  @Test("CloudKit 429 rate limit error is retriable")
  internal func testCloudKit429Retriable() {
    let ckError = CloudKitError.httpError(statusCode: 429)
    let error = CelestraError.cloudKitError(ckError)

    #expect(error.isRetriable == true)
  }

  @Test("CloudKit 4xx client errors are not retriable")
  internal func testCloudKit4xxNotRetriable() {
    let ckError = CloudKitError.httpError(statusCode: 400)
    let error = CelestraError.cloudKitError(ckError)

    #expect(error.isRetriable == false)
  }

  @Test("CloudKit 404 error is not retriable")
  internal func testCloudKit404NotRetriable() {
    let ckError = CloudKitError.httpError(statusCode: 404)
    let error = CelestraError.cloudKitError(ckError)

    #expect(error.isRetriable == false)
  }

  @Test("CloudKit network error is retriable")
  internal func testCloudKitNetworkErrorRetriable() {
    let urlError = URLError(.networkConnectionLost)
    let ckError = CloudKitError.networkError(urlError)
    let error = CelestraError.cloudKitError(ckError)

    #expect(error.isRetriable == true)
  }

  @Test("CloudKit invalid response is retriable")
  internal func testCloudKitInvalidResponseRetriable() {
    let ckError = CloudKitError.invalidResponse
    let error = CelestraError.cloudKitError(ckError)

    #expect(error.isRetriable == true)
  }
}

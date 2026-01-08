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
  internal func testRSSFetchFailedRetriable() {
    let url = URL(string: "https://example.com/feed.xml")!
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
  internal func testRSSFetchFailedDescription() {
    let url = URL(string: "https://example.com/feed.xml")!
    let underlyingError = NSError(domain: "Test", code: 1, userInfo: [
      NSLocalizedDescriptionKey: "Connection timeout",
    ])
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
  internal func testRSSFetchFailedRecoverySuggestion() {
    let url = URL(string: "https://example.com/feed.xml")!
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

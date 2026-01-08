//
//  AuthenticationErrorHandlingTests.swift
//  BushelCloud
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
import Testing

// MARK: - Authentication Error Handling Tests

@Suite("Authentication Error Handling Tests")
internal struct AuthenticationErrorHandlingTests {
  @Test("CloudKit authentication failure")
  internal func testCloudKitAuthFailure() async {
    let service = MockCloudKitService()
    await service.setShouldFailQuery(true)
    await service.setQueryError(MockCloudKitError.authenticationFailed)

    do {
      _ = try await service.queryRecords(recordType: "RestoreImage")
      Issue.record("Expected authentication error to be thrown")
    } catch let error as MockCloudKitError {
      if case .authenticationFailed = error {
        // Success
      } else {
        Issue.record("Wrong error type: \(error)")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("CloudKit access denied")
  internal func testCloudKitAccessDenied() async {
    let service = MockCloudKitService()
    await service.setShouldFailQuery(true)
    await service.setQueryError(MockCloudKitError.accessDenied)

    do {
      _ = try await service.queryRecords(recordType: "RestoreImage")
      Issue.record("Expected access denied error to be thrown")
    } catch let error as MockCloudKitError {
      if case .accessDenied = error {
        // Success
      } else {
        Issue.record("Wrong error type: \(error)")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Data source authentication failure")
  internal func testDataSourceAuthFailure() async {
    let fetcher = MockXcodeReleasesFetcher(
      errorToThrow: MockFetcherError.authenticationFailed
    )

    do {
      _ = try await fetcher.fetch()
      Issue.record("Expected authentication error to be thrown")
    } catch is MockFetcherError {
      // Success
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }
}

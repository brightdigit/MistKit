//
//  MockAppleDBFetcherTests.swift
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

@testable import BushelFoundation

// MARK: - Mock AppleDB Fetcher Tests

@Suite("Mock AppleDB Fetcher Tests")
internal struct MockAppleDBFetcherTests {
  @Test("Successful fetch returns records")
  internal func testSuccessfulFetch() async throws {
    let expectedRecords = [TestFixtures.sonoma1421Appledb]
    let fetcher = MockAppleDBFetcher(recordsToReturn: expectedRecords)

    let result = try await fetcher.fetch()

    #expect(result.count == 1)
    #expect(result[0].source == "appledb.dev")
  }

  @Test("Server error throws expected error")
  internal func testServerError() async {
    let expectedError = MockFetcherError.serverError(code: 500)
    let fetcher = MockAppleDBFetcher(errorToThrow: expectedError)

    do {
      _ = try await fetcher.fetch()
      Issue.record("Expected error to be thrown")
    } catch let error as MockFetcherError {
      if case .serverError(let code) = error {
        #expect(code == 500)
      } else {
        Issue.record("Wrong error type thrown")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }
}

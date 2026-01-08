//
//  MockIPSWFetcherTests.swift
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

// MARK: - Mock IPSW Fetcher Tests

@Suite("Mock IPSW Fetcher Tests")
internal struct MockIPSWFetcherTests {
  @Test("Successful fetch returns records")
  internal func testSuccessfulFetch() async throws {
    let expectedRecords = [TestFixtures.sonoma1421, TestFixtures.sequoia150Beta]
    let fetcher = MockIPSWFetcher(recordsToReturn: expectedRecords)

    let result = try await fetcher.fetch()

    #expect(result.count == 2)
    #expect(result[0].buildNumber == "23C71")
    #expect(result[1].buildNumber == "24A5264n")
  }

  @Test("Empty fetch returns empty array")
  internal func testEmptyFetch() async throws {
    let fetcher = MockIPSWFetcher(recordsToReturn: [])

    let result = try await fetcher.fetch()

    #expect(result.isEmpty)
  }

  @Test("Network error throws expected error")
  internal func testNetworkError() async {
    let expectedError = MockFetcherError.networkError("Connection timeout")
    let fetcher = MockIPSWFetcher(errorToThrow: expectedError)

    do {
      _ = try await fetcher.fetch()
      Issue.record("Expected error to be thrown")
    } catch let error as MockFetcherError {
      if case .networkError(let message) = error {
        #expect(message == "Connection timeout")
      } else {
        Issue.record("Wrong error type thrown")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }
}

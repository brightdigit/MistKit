//
//  GracefulDegradationTests.swift
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

// MARK: - Graceful Degradation Tests

@Suite("Graceful Degradation Tests")
internal struct GracefulDegradationTests {
  @Test("Single fetcher failure doesn't block others")
  internal func testPartialFetcherFailure() async {
    // Simulate one fetcher failing while others succeed
    let ipswFetcher = MockIPSWFetcher(
      recordsToReturn: [TestFixtures.sonoma1421]
    )
    let appleDBFetcher = MockAppleDBFetcher(
      errorToThrow: MockFetcherError.networkError("Network unavailable")
    )

    // IPSW should succeed
    do {
      let ipswResults = try await ipswFetcher.fetch()
      #expect(ipswResults.count == 1)
    } catch {
      Issue.record("IPSW fetcher should have succeeded")
    }

    // AppleDB should fail gracefully
    do {
      _ = try await appleDBFetcher.fetch()
      Issue.record("AppleDB fetcher should have failed")
    } catch {
      // Expected to fail
    }
  }

  @Test("Empty results handled gracefully")
  internal func testEmptyResults() async throws {
    let fetcher = MockIPSWFetcher(recordsToReturn: [])
    let results = try await fetcher.fetch()
    #expect(results.isEmpty)
  }

  @Test("Nil results from optional fetcher")
  internal func testNilResults() async throws {
    let fetcher = MockMESUFetcher(recordToReturn: nil)
    let result = try await fetcher.fetch()
    #expect(result == nil)
  }
}

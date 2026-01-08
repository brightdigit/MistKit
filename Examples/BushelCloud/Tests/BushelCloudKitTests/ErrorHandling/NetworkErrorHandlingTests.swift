//
//  NetworkErrorHandlingTests.swift
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

// MARK: - Network Error Handling Tests

@Suite("Network Error Handling Tests")
internal struct NetworkErrorHandlingTests {
  @Test("Handle network timeout gracefully")
  internal func testNetworkTimeout() async {
    let fetcher = MockIPSWFetcher(errorToThrow: MockFetcherError.timeout)

    do {
      _ = try await fetcher.fetch()
      Issue.record("Expected timeout error to be thrown")
    } catch let error as MockFetcherError {
      if case .timeout = error {
        // Success - timeout handled correctly
      } else {
        Issue.record("Wrong error type: \(error)")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Handle connection failure")
  internal func testConnectionFailure() async {
    let fetcher = MockAppleDBFetcher(
      errorToThrow: MockFetcherError.networkError("Connection refused")
    )

    do {
      _ = try await fetcher.fetch()
      Issue.record("Expected network error to be thrown")
    } catch let error as MockFetcherError {
      if case .networkError(let message) = error {
        #expect(message.contains("refused"))
      } else {
        Issue.record("Wrong error type: \(error)")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Handle DNS resolution failure")
  internal func testDNSFailure() async {
    let fetcher = MockXcodeReleasesFetcher(
      errorToThrow: MockFetcherError.networkError("DNS resolution failed")
    )

    do {
      _ = try await fetcher.fetch()
      Issue.record("Expected DNS error to be thrown")
    } catch let error as MockFetcherError {
      if case .networkError(let message) = error {
        #expect(message.contains("DNS"))
      } else {
        Issue.record("Wrong error type: \(error)")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Handle server errors (5xx)")
  internal func testServerErrors() async {
    for errorCode in [500, 502, 503, 504] {
      let fetcher = MockAppleDBFetcher(
        errorToThrow: MockFetcherError.serverError(code: errorCode)
      )

      do {
        _ = try await fetcher.fetch()
        Issue.record("Expected server error \(errorCode) to be thrown")
      } catch let error as MockFetcherError {
        if case .serverError(let code) = error {
          #expect(code == errorCode)
        } else {
          Issue.record("Wrong error type: \(error)")
        }
      } catch {
        Issue.record("Unexpected error type: \(error)")
      }
    }
  }

  @Test("Handle client errors (4xx)")
  internal func testClientErrors() async {
    for errorCode in [400, 401, 403, 404, 429] {
      let fetcher = MockIPSWFetcher(
        errorToThrow: MockFetcherError.serverError(code: errorCode)
      )

      do {
        _ = try await fetcher.fetch()
        Issue.record("Expected client error \(errorCode) to be thrown")
      } catch let error as MockFetcherError {
        if case .serverError(let code) = error {
          #expect(code == errorCode)
        } else {
          Issue.record("Wrong error type: \(error)")
        }
      } catch {
        Issue.record("Unexpected error type: \(error)")
      }
    }
  }

  @Test("Handle invalid response data")
  internal func testInvalidResponse() async {
    let fetcher = MockMESUFetcher(errorToThrow: MockFetcherError.invalidResponse)

    do {
      _ = try await fetcher.fetch()
      Issue.record("Expected invalid response error to be thrown")
    } catch is MockFetcherError {
      // Success
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }
}

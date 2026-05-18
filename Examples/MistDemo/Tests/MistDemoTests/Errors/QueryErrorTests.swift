//
//  QueryErrorTests.swift
//  MistDemo
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

internal import Foundation
internal import Testing

@testable import MistDemoKit

@Suite("QueryError Tests")
internal struct QueryErrorTests {
  // MARK: - Error Description Tests

  @Test("invalidLimit error description")
  internal func invalidLimitDescription() {
    let error = QueryError.invalidLimit(500)
    let description = error.errorDescription

    #expect(description != nil)
    #expect(description?.contains("500") == true)
    #expect(description?.contains(String(MistDemoConstants.Limits.minQueryLimit)) == true)
    #expect(description?.contains(String(MistDemoConstants.Limits.maxQueryLimit)) == true)
  }

  @Test("invalidFilter error description")
  internal func invalidFilterDescription() {
    let error = QueryError.invalidFilter("invalid:filter", expected: "field:op:value")
    let description = error.errorDescription

    #expect(description != nil)
    #expect(description?.contains("Invalid filter") == true)
    #expect(description?.contains("invalid:filter") == true)
    #expect(description?.contains("field:op:value") == true)
  }

  @Test("emptyFieldName error description")
  internal func emptyFieldNameDescription() {
    let error = QueryError.emptyFieldName(":eq:value")
    let description = error.errorDescription

    #expect(description != nil)
    #expect(description?.contains("Empty field name") == true)
    #expect(description?.contains(":eq:value") == true)
  }

  @Test("invalidSortOrder error description")
  internal func invalidSortOrderDescription() {
    let error = QueryError.invalidSortOrder("invalid", available: ["asc", "desc"])
    let description = error.errorDescription

    #expect(description != nil)
    #expect(description?.contains("Invalid sort order") == true)
    #expect(description?.contains("invalid") == true)
    #expect(description?.contains("asc") == true)
    #expect(description?.contains("desc") == true)
  }

  @Test("unsupportedOperator error description")
  internal func unsupportedOperatorDescription() {
    let error = QueryError.unsupportedOperator("regex")
    let description = error.errorDescription

    #expect(description != nil)
    #expect(description?.contains("Unsupported filter operator") == true)
    #expect(description?.contains("regex") == true)
    #expect(description?.contains("eq") == true)
    #expect(description?.contains("ne") == true)
    #expect(description?.contains("gt") == true)
  }

  @Test("operationFailed error description")
  internal func operationFailedDescription() {
    let error = QueryError.operationFailed("network error")
    let description = error.errorDescription

    #expect(description != nil)
    #expect(description?.contains("Query operation failed") == true)
    #expect(description?.contains("network error") == true)
  }

  // MARK: - LocalizedError Conformance Tests

  @Test("QueryError conforms to LocalizedError")
  internal func conformsToLocalizedError() {
    let error: any Error = QueryError.invalidLimit(0)
    #expect(error is LocalizedError)
  }

  @Test("All error cases have non-nil descriptions")
  internal func allCasesHaveDescriptions() {
    let errors: [QueryError] = [
      .invalidLimit(500),
      .invalidFilter("filter", expected: "expected"),
      .emptyFieldName("filter"),
      .invalidSortOrder("order", available: ["asc", "desc"]),
      .unsupportedOperator("op"),
      .operationFailed("reason"),
    ]

    for error in errors {
      #expect(error.errorDescription != nil)
      #expect(error.errorDescription?.isEmpty == false)
    }
  }

  // MARK: - Error Throwing Tests

  @Test("Can throw and catch QueryError")
  internal func throwAndCatch() {
    #expect(throws: QueryError.self) {
      throw QueryError.invalidLimit(0)
    }
  }

  @Test("Can pattern match on specific error case")
  internal func patternMatch() {
    let error = QueryError.invalidLimit(500)

    if case .invalidLimit(let limit) = error {
      #expect(limit == 500)
    } else {
      Issue.record("Pattern match failed")
    }
  }

  // MARK: - Specific Error Case Tests

  @Test("invalidLimit with negative value")
  internal func invalidLimitNegative() throws {
    let error = QueryError.invalidLimit(-1)
    let description = try #require(error.errorDescription)

    #expect(description.contains("-1"))
  }

  @Test("invalidSortOrder shows all available options")
  internal func invalidSortOrderShowsOptions() throws {
    let availableOrders = ["asc", "desc", "ascending", "descending"]
    let error = QueryError.invalidSortOrder("bad", available: availableOrders)
    let description = try #require(error.errorDescription)

    for order in availableOrders {
      #expect(description.contains(order))
    }
  }

  @Test("unsupportedOperator lists supported operators")
  internal func unsupportedOperatorListsSupported() throws {
    let error = QueryError.unsupportedOperator("unknown")
    let description = try #require(error.errorDescription)

    let supportedOps = [
      "eq", "ne", "gt", "gte", "lt", "lte", "contains", "begins_with", "in", "not_in",
    ]
    for supportedOp in supportedOps {
      #expect(description.contains(supportedOp))
    }
  }
}

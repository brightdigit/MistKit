//
//  CloudKitServiceQueryTests.swift
//  MistKit
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

@testable import MistKit

/// Integration tests for CloudKitService queryRecords() functionality
@Suite("CloudKitService Query Operations", .enabled(if: Platform.isCryptoAvailable))
struct CloudKitServiceQueryTests {
  // MARK: - Configuration Tests

  @Test("queryRecords() uses default limit from configuration")
  func queryRecordsUsesDefaultLimit() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    // This test verifies that the default limit configuration is respected
    // In a real integration test, we would mock the HTTP client and verify the request
    let service = try CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: "test-token"
    )

    // Verify default configuration
    #expect(service.defaultQueryLimit == 100)
    #expect(service.defaultBatchSize == 100)
  }

  @Test("queryRecords() with custom default limit")
  func queryRecordsWithCustomDefaultLimit() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    var service = try CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: "test-token"
    )

    // Set custom default
    service.defaultQueryLimit = 50

    #expect(service.defaultQueryLimit == 50)
  }

  // MARK: - Validation Tests

  @Test("queryRecords() validates empty recordType")
  func queryRecordsValidatesEmptyRecordType() async {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let service = try! CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: "test-token"
    )

    do {
      _ = try await service.queryRecords(recordType: "")
      Issue.record("Expected error for empty recordType")
    } catch let error as CloudKitError {
      // Verify we get the correct validation error
      if case .httpErrorWithRawResponse(let statusCode, let response) = error {
        #expect(statusCode == 400)
        #expect(response.contains("recordType cannot be empty"))
      } else {
        Issue.record("Expected httpErrorWithRawResponse error")
      }
    } catch {
      Issue.record("Expected CloudKitError, got \(type(of: error))")
    }
  }

  @Test("queryRecords() validates limit too small", arguments: [-1, 0])
  func queryRecordsValidatesLimitTooSmall(limit: Int) async {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let service = try! CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: "test-token"
    )

    do {
      _ = try await service.queryRecords(recordType: "Article", limit: limit)
      Issue.record("Expected error for limit \(limit)")
    } catch let error as CloudKitError {
      if case .httpErrorWithRawResponse(let statusCode, let response) = error {
        #expect(statusCode == 400)
        #expect(response.contains("limit must be between 1 and 200"))
      } else {
        Issue.record("Expected httpErrorWithRawResponse error")
      }
    } catch {
      Issue.record("Expected CloudKitError")
    }
  }

  @Test("queryRecords() validates limit too large", arguments: [201, 300, 1_000])
  func queryRecordsValidatesLimitTooLarge(limit: Int) async {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let service = try! CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: "test-token"
    )

    do {
      _ = try await service.queryRecords(recordType: "Article", limit: limit)
      Issue.record("Expected error for limit \(limit)")
    } catch let error as CloudKitError {
      if case .httpErrorWithRawResponse(let statusCode, let response) = error {
        #expect(statusCode == 400)
        #expect(response.contains("limit must be between 1 and 200"))
      } else {
        Issue.record("Expected httpErrorWithRawResponse error")
      }
    } catch {
      Issue.record("Expected CloudKitError")
    }
  }

  @Test("queryRecords() accepts valid limit range", arguments: [1, 50, 100, 200])
  func queryRecordsAcceptsValidLimitRange(limit: Int) async {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let service = try! CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: "test-token"
    )

    // This test verifies validation passes - actual API call will fail without real credentials
    // but we're testing that validation doesn't throw
    do {
      _ = try await service.queryRecords(recordType: "Article", limit: limit)
      Issue.record("Expected network error since we don't have real credentials")
    } catch let error as CloudKitError {
      // We expect a network/auth error, not a validation error
      // Validation errors have status code 400
      if case .httpErrorWithRawResponse(let statusCode, _) = error {
        #expect(statusCode != 400, "Validation should not fail for limit \(limit)")
      }
      // Other CloudKit errors are expected (auth, network, etc.)
    } catch {
      // Network errors are expected
    }
  }

  // MARK: - Filter Conversion Tests

  @Test("QueryFilter converts to Components.Schemas format correctly")
  func queryFilterConvertsToComponentsFormat() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    // Test equality filter
    let equalFilter = QueryFilter.equals("title", .string("Test"))
    let componentsFilter = equalFilter.toComponentsFilter()

    #expect(componentsFilter.fieldName == "title")
    #expect(componentsFilter.comparator == .EQUALS)

    // Test comparison filter
    let greaterThanFilter = QueryFilter.greaterThan("count", .int64(10))
    let componentsGT = greaterThanFilter.toComponentsFilter()

    #expect(componentsGT.fieldName == "count")
    #expect(componentsGT.comparator == .GREATER_THAN)
  }

  @Test("QueryFilter handles all field value types")
  func queryFilterHandlesAllFieldValueTypes() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let testCases: [(FieldValue, String)] = [
      (.string("test"), "string"),
      (.int64(42), "int64"),
      (.double(3.14), "double"),
      (.boolean(true), "boolean"),
      (.date(Date()), "date"),
    ]

    for (fieldValue, typeName) in testCases {
      let filter = QueryFilter.equals("field", fieldValue)
      let components = filter.toComponentsFilter()

      #expect(components.fieldName == "field")
      #expect(components.comparator == .EQUALS, "Failed for \(typeName)")
    }
  }

  // MARK: - Sort Conversion Tests

  @Test("QuerySort converts to Components.Schemas format correctly")
  func querySortConvertsToComponentsFormat() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    // Test ascending sort
    let ascendingSort = QuerySort.ascending("createdAt")
    let componentsAsc = ascendingSort.toComponentsSort()

    #expect(componentsAsc.fieldName == "createdAt")
    #expect(componentsAsc.ascending == true)

    // Test descending sort
    let descendingSort = QuerySort.descending("modifiedAt")
    let componentsDesc = descendingSort.toComponentsSort()

    #expect(componentsDesc.fieldName == "modifiedAt")
    #expect(componentsDesc.ascending == false)
  }

  @Test("QuerySort handles various field name formats")
  func querySortHandlesVariousFieldNameFormats() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let fieldNames = [
      "simpleField",
      "camelCaseField",
      "snake_case_field",
      "field123",
      "field_with_multiple_underscores",
    ]

    for fieldName in fieldNames {
      let sort = QuerySort.ascending(fieldName)
      let components = sort.toComponentsSort()

      #expect(components.fieldName == fieldName, "Failed for field name: \(fieldName)")
    }
  }

  // MARK: - Edge Cases

  @Test("queryRecords() handles nil limit parameter")
  func queryRecordsHandlesNilLimitParameter() async {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let service = try! CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: "test-token"
    )

    // With nil limit, should use defaultQueryLimit (100)
    // This test verifies the parameter handling - actual call will fail without auth
    do {
      _ = try await service.queryRecords(recordType: "Article", limit: nil as Int?)
    } catch let error as CloudKitError {
      // Validation should pass (no 400 error)
      if case .httpErrorWithRawResponse(let statusCode, _) = error {
        #expect(statusCode != 400, "Should not fail validation with nil limit")
      }
    } catch {
      // Other errors are expected
    }
  }

  @Test("queryRecords() handles empty filters array")
  func queryRecordsHandlesEmptyFiltersArray() async {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let service = try! CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: "test-token"
    )

    do {
      _ = try await service.queryRecords(
        recordType: "Article",
        filters: [],
        limit: 10
      )
    } catch let error as CloudKitError {
      // Should not fail validation
      if case .httpErrorWithRawResponse(let statusCode, _) = error {
        #expect(statusCode != 400, "Should not fail validation with empty filters")
      }
    } catch {
      // Other errors expected
    }
  }

  @Test("queryRecords() handles empty sorts array")
  func queryRecordsHandlesEmptySortsArray() async {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let service = try! CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: "test-token"
    )

    do {
      _ = try await service.queryRecords(
        recordType: "Article",
        sortBy: [],
        limit: 10
      )
    } catch let error as CloudKitError {
      // Should not fail validation
      if case .httpErrorWithRawResponse(let statusCode, _) = error {
        #expect(statusCode != 400, "Should not fail validation with empty sorts")
      }
    } catch {
      // Other errors expected
    }
  }
}

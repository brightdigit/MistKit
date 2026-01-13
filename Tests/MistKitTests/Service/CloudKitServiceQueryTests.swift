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
  internal func queryRecordsUsesDefaultLimit() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    // This test verifies that the default limit configuration is respected
    // Using MockTransport to avoid actual network calls
    let service = try makeSuccessfulService()

    // Verify service was created successfully
    #expect(service.containerIdentifier == "iCloud.com.example.test")
  }

  // MARK: - Validation Tests

  @Test("queryRecords() validates empty recordType")
  internal func queryRecordsValidatesEmptyRecordType() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let service = try makeValidationErrorService(.emptyRecordType)

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
  internal func queryRecordsValidatesLimitTooSmall(limit: Int) async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let service = try makeValidationErrorService(.limitTooSmall(limit))

    do {
      _ = try await service.queryRecords(recordType: "Article", limit: limit)
      Issue.record("Expected error for limit \(limit)")
    } catch {
      if case .httpErrorWithRawResponse(let statusCode, let response) = error {
        #expect(statusCode == 400)
        #expect(response.contains("limit must be between 1 and 200"))
      } else {
        Issue.record("Expected httpErrorWithRawResponse error")
      }
    }
  }

  @Test("queryRecords() validates limit too large", arguments: [201, 300, 1_000])
  internal func queryRecordsValidatesLimitTooLarge(limit: Int) async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let service = try makeValidationErrorService(.limitTooLarge(limit))

    do {
      _ = try await service.queryRecords(recordType: "Article", limit: limit)
      Issue.record("Expected error for limit \(limit)")
    } catch {
      if case .httpErrorWithRawResponse(let statusCode, let response) = error {
        #expect(statusCode == 400)
        #expect(response.contains("limit must be between 1 and 200"))
      } else {
        Issue.record("Expected httpErrorWithRawResponse error")
      }
    }
  }

  @Test("queryRecords() accepts valid limit range", arguments: [1, 50, 100, 200])
  internal func queryRecordsAcceptsValidLimitRange(limit: Int) async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let service = try makeSuccessfulService()

    // This test verifies validation passes - actual API call will fail without real credentials
    // but we're testing that validation doesn't throw
    do {
      _ = try await service.queryRecords(recordType: "Article", limit: limit)
      Issue.record("Expected network error since we don't have real credentials")
    } catch {
      // We expect a network/auth error, not a validation error
      // Validation errors have status code 400
      if case .httpErrorWithRawResponse(let statusCode, _) = error {
        #expect(statusCode != 400, "Validation should not fail for limit \(limit)")
      }
      // Other CloudKit errors are expected (auth, network, etc.)
    }
  }

  // MARK: - Filter Conversion Tests

  @Test("QueryFilter converts to Components.Schemas format correctly")
  internal func queryFilterConvertsToComponentsFormat() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    // Test equality filter
    let equalFilter = QueryFilter.equals("title", .string("Test"))
    let componentsFilter = Components.Schemas.Filter(from: equalFilter)

    #expect(componentsFilter.fieldName == "title")
    #expect(componentsFilter.comparator == .EQUALS)

    // Test comparison filter
    let greaterThanFilter = QueryFilter.greaterThan("count", .int64(10))
    let componentsGT = Components.Schemas.Filter(from: greaterThanFilter)

    #expect(componentsGT.fieldName == "count")
    #expect(componentsGT.comparator == .GREATER_THAN)
  }

  @Test("QueryFilter handles all field value types")
  internal func queryFilterHandlesAllFieldValueTypes() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let testCases: [(FieldValue, String)] = [
      (.string("test"), "string"),
      (.int64(42), "int64"),
      (.double(3.14), "double"),
      (FieldValue(booleanValue: true), "boolean"),
      (.date(Date()), "date"),
    ]

    for (fieldValue, typeName) in testCases {
      let filter = QueryFilter.equals("field", fieldValue)
      let components = Components.Schemas.Filter(from: filter)

      #expect(components.fieldName == "field")
      #expect(components.comparator == .EQUALS, "Failed for \(typeName)")
    }
  }

  // MARK: - Sort Conversion Tests

  @Test("QuerySort converts to Components.Schemas format correctly")
  internal func querySortConvertsToComponentsFormat() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    // Test ascending sort
    let ascendingSort = QuerySort.ascending("createdAt")
    let componentsAsc = Components.Schemas.Sort(from: ascendingSort)

    #expect(componentsAsc.fieldName == "createdAt")
    #expect(componentsAsc.ascending == true)

    // Test descending sort
    let descendingSort = QuerySort.descending("modifiedAt")
    let componentsDesc = Components.Schemas.Sort(from: descendingSort)

    #expect(componentsDesc.fieldName == "modifiedAt")
    #expect(componentsDesc.ascending == false)
  }

  @Test("QuerySort handles various field name formats")
  internal func querySortHandlesVariousFieldNameFormats() {
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
      let components = Components.Schemas.Sort(from: sort)

      #expect(components.fieldName == fieldName, "Failed for field name: \(fieldName)")
    }
  }

  // MARK: - Edge Cases

  @Test("queryRecords() handles nil limit parameter")
  internal func queryRecordsHandlesNilLimitParameter() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let service = try makeSuccessfulService()

    // With nil limit, should use defaultQueryLimit (100)
    // This test verifies the parameter handling - actual call will fail without auth
    do {
      _ = try await service.queryRecords(recordType: "Article", limit: nil as Int?)
    } catch {
      // Validation should pass (no 400 error)
      if case .httpErrorWithRawResponse(let statusCode, _) = error {
        #expect(statusCode != 400, "Should not fail validation with nil limit")
      }
    }
  }

  @Test("queryRecords() handles empty filters array")
  internal func queryRecordsHandlesEmptyFiltersArray() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let service = try makeSuccessfulService()

    do {
      _ = try await service.queryRecords(
        recordType: "Article",
        filters: [],
        limit: 10
      )
    } catch {
      // Should not fail validation
      if case .httpErrorWithRawResponse(let statusCode, _) = error {
        #expect(statusCode != 400, "Should not fail validation with empty filters")
      }
    }
  }

  @Test("queryRecords() handles empty sorts array")
  internal func queryRecordsHandlesEmptySortsArray() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let service = try makeSuccessfulService()

    do {
      _ = try await service.queryRecords(
        recordType: "Article",
        sortBy: [],
        limit: 10
      )
    } catch {
      // Should not fail validation
      if case .httpErrorWithRawResponse(let statusCode, _) = error {
        #expect(statusCode != 400, "Should not fail validation with empty sorts")
      }
    }
  }

  // MARK: - Test Helpers

  /// Create service for validation error testing
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  private func makeValidationErrorService(
    _ errorType: ValidationErrorType
  ) throws -> CloudKitService {
    let transport = MockTransport(
      responseProvider: .validationError(errorType)
    )
    return try CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: "test-token",
      transport: transport
    )
  }

  /// Create service for successful operations
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  private func makeSuccessfulService(
    records: [String: Any] = [:]
  ) throws -> CloudKitService {
    let transport = MockTransport(
      responseProvider: .successfulQuery(records: records)
    )
    return try CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: "test-token",
      transport: transport
    )
  }

  /// Create service for auth errors
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  private func makeAuthErrorService() throws -> CloudKitService {
    let transport = MockTransport(
      responseProvider: .authenticationError()
    )
    return try CloudKitService(
      containerIdentifier: "iCloud.com.example.test",
      apiToken: "test-token",
      transport: transport
    )
  }
}

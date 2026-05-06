//
//  CloudKitServiceQueryTests+Validation.swift
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

extension CloudKitServiceQueryTests {
  @Suite("Validation")
  internal struct Validation {
    @Test("queryRecords() validates empty recordType")
    internal func queryRecordsValidatesEmptyRecordType() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceQueryTests.makeValidationErrorService(.emptyRecordType)

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
      let service = try CloudKitServiceQueryTests.makeValidationErrorService(.limitTooSmall(limit))

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
      let service = try CloudKitServiceQueryTests.makeValidationErrorService(.limitTooLarge(limit))

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
      let service = try CloudKitServiceQueryTests.makeSuccessfulService()

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
  }
}

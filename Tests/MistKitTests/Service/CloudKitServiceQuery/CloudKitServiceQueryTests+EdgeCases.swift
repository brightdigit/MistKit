//
//  CloudKitServiceQueryTests+EdgeCases.swift
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
  @Suite("Edge Cases")
  internal struct EdgeCases {
    @Test("queryRecords() handles nil limit parameter")
    internal func queryRecordsHandlesNilLimitParameter() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceQueryTests.makeSuccessfulService()

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
      let service = try CloudKitServiceQueryTests.makeSuccessfulService()

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
      let service = try CloudKitServiceQueryTests.makeSuccessfulService()

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
  }
}

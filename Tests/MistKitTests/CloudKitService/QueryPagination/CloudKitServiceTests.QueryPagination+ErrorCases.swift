//
//  CloudKitServiceTests.QueryPagination+ErrorCases.swift
//  MistKit
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

import Foundation
import Testing

@testable import MistKit

extension CloudKitServiceTests.QueryPagination {
  @Suite("Error Cases")
  internal struct ErrorCases {
    @Test("queryAllRecords() throws paginationLimitExceeded carrying collected records")
    internal func queryAllRecordsOverflowReturnsAccumulatedRecords() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.QueryPagination.makePaginatedService(
        pages: [
          (recordCount: 3, continuationMarker: "marker-1"),
          (recordCount: 2, continuationMarker: "marker-2"),
          (recordCount: 5, continuationMarker: "marker-3"),
        ]
      )

      do {
        _ = try await service.queryAllRecords(
          recordType: "TestRecord",
          maxPages: 2,
          database: .public(.prefers(.serverToServer))
        )
        Issue.record("Expected paginationLimitExceeded to be thrown")
      } catch CloudKitError.paginationLimitExceeded(let maxPages, let records) {
        #expect(maxPages == 2)
        #expect(records.count == 5)
        #expect(
          records.map(\.recordName) == [
            "record-0", "record-1", "record-2",
            "record-0", "record-1",
          ])
      } catch {
        Issue.record("Expected paginationLimitExceeded, got \(error)")
      }
    }
  }
}

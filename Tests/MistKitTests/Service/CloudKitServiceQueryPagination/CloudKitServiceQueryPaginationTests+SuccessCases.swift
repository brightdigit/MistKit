//
//  CloudKitServiceQueryPaginationTests+SuccessCases.swift
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
  @Suite("Success Cases")
  internal struct SuccessCases {

    // MARK: - queryRecords returning QueryResult

    @Test("queryRecords() returns QueryResult with records and nil continuationMarker")
    internal func queryRecordsReturnsQueryResultNoContinuation() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.QueryPagination.makeSuccessfulService(
        recordCount: 3,
        continuationMarker: nil
      )

      let result: QueryResult = try await service.queryRecords(
        recordType: "TestRecord",
        continuationMarker: nil
      )

      #expect(result.records.count == 3)
      #expect(result.continuationMarker == nil)
    }

    @Test("queryRecords() returns QueryResult with continuationMarker")
    internal func queryRecordsReturnsQueryResultWithContinuation() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.QueryPagination.makeSuccessfulService(
        recordCount: 2,
        continuationMarker: "marker-abc"
      )

      let result: QueryResult = try await service.queryRecords(
        recordType: "TestRecord"
      )

      #expect(result.records.count == 2)
      #expect(result.continuationMarker == "marker-abc")
    }

    @Test("queryRecords() with continuationMarker parameter returns next page")
    internal func queryRecordsWithContinuationMarkerReturnsNextPage() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.QueryPagination.makeSuccessfulService(
        recordCount: 1,
        continuationMarker: nil
      )

      let result: QueryResult = try await service.queryRecords(
        recordType: "TestRecord",
        continuationMarker: "previous-marker"
      )

      #expect(result.records.count == 1)
      #expect(result.continuationMarker == nil)
    }

    // MARK: - queryAllRecords

    @Test("queryAllRecords() returns records when no pagination needed")
    internal func queryAllRecordsNoPagination() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.QueryPagination.makePaginatedService(
        pages: [
          (recordCount: 3, continuationMarker: nil)
        ]
      )

      let records = try await service.queryAllRecords(recordType: "TestRecord")

      #expect(records.count == 3)
    }

    @Test("queryAllRecords() accumulates records across two pages")
    internal func queryAllRecordsMultiPage() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.QueryPagination.makePaginatedService(
        pages: [
          (recordCount: 3, continuationMarker: "marker-1"),
          (recordCount: 2, continuationMarker: nil),
        ]
      )

      let records = try await service.queryAllRecords(recordType: "TestRecord")

      #expect(records.count == 5)
    }

    @Test("queryAllRecords() accumulates records across three pages")
    internal func queryAllRecordsThreePages() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.QueryPagination.makePaginatedService(
        pages: [
          (recordCount: 2, continuationMarker: "marker-1"),
          (recordCount: 3, continuationMarker: "marker-2"),
          (recordCount: 1, continuationMarker: nil),
        ]
      )

      let records = try await service.queryAllRecords(recordType: "TestRecord")

      #expect(records.count == 6)
    }

    @Test("queryAllRecords() breaks on stuck marker (empty records, same marker)")
    internal func queryAllRecordsStuckMarkerDetection() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      // First page returns records with a marker, second page returns no records
      // but same marker (stuck). The method should break out of the loop.
      let provider = ResponseProvider(
        defaultResponse: .successfulQueryResponse(
          recordCount: 0,
          continuationMarker: "stuck-marker"
        )
      )
      await provider.enqueue(
        .successfulQueryResponse(
          recordCount: 2,
          continuationMarker: "stuck-marker"
        ),
        for: "queryRecords"
      )
      let transport = MockTransport(responseProvider: provider)
      let service = try CloudKitService(
        containerIdentifier: TestConstants.serviceContainerIdentifier,
        apiToken: TestConstants.apiToken,
        transport: transport
      )

      let records = try await service.queryAllRecords(recordType: "TestRecord")

      // Should get the 2 records from page 1, then break on page 2 (stuck marker)
      #expect(records.count == 2)
    }

    @Test("queryAllRecords() handles empty first page with continuation")
    internal func queryAllRecordsEmptyFirstPage() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.QueryPagination.makePaginatedService(
        pages: [
          (recordCount: 0, continuationMarker: "marker-1"),
          (recordCount: 3, continuationMarker: nil),
        ]
      )

      let records = try await service.queryAllRecords(recordType: "TestRecord")

      #expect(records.count == 3)
    }
  }
}

//
//  CloudKitServiceFetchChangesTests+SuccessCases.swift
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

extension CloudKitServiceFetchChangesTests {
  @Suite("Success Cases")
  internal struct SuccessCases {
    @Test("fetchRecordChanges() returns records and sync token")
    internal func fetchRecordChangesReturnsRecordsAndToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceFetchChangesTests.makeSuccessfulService(
        recordCount: 3,
        syncToken: "new-token-123"
      )

      let result = try await service.fetchRecordChanges()

      #expect(result.records.count == 3)
      #expect(result.syncToken == "new-token-123")
      #expect(result.moreComing == false)
    }

    @Test("fetchRecordChanges() reports moreComing flag")
    internal func fetchRecordChangesReportsMoreComing() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceFetchChangesTests.makeSuccessfulService(
        recordCount: 2,
        moreComing: true
      )

      let result = try await service.fetchRecordChanges()

      #expect(result.moreComing == true)
      #expect(result.records.count == 2)
    }

    @Test("fetchRecordChanges() works without sync token (initial fetch)")
    internal func fetchRecordChangesWorksWithoutSyncToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceFetchChangesTests.makeSuccessfulService()

      let result = try await service.fetchRecordChanges(syncToken: nil)

      #expect(result.records.isEmpty == false)
      #expect(result.syncToken != nil)
    }

    @Test("fetchRecordChanges() returns record names and types")
    internal func fetchRecordChangesReturnsRecordDetails() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceFetchChangesTests.makeSuccessfulService(recordCount: 2)

      let result = try await service.fetchRecordChanges()

      #expect(result.records[0].recordName == "record-0")
      #expect(result.records[0].recordType == "Note")
      #expect(result.records[1].recordName == "record-1")
    }

    @Test("fetchAllRecordChanges() returns records when no pagination needed")
    internal func fetchAllRecordChangesNoPagination() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceFetchChangesTests.makeSuccessfulService(
        recordCount: 3,
        moreComing: false,
        syncToken: "final-token"
      )

      let (records, token) = try await service.fetchAllRecordChanges()

      #expect(records.count == 3)
      #expect(token == "final-token")
    }

    @Test("fetchAllRecordChanges() accumulates records across two pages")
    internal func fetchAllRecordChangesMultiPage() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceFetchChangesTests.makePaginatedService(pages: [
        (recordCount: 3, syncToken: "token-1"),
        (recordCount: 2, syncToken: "token-2"),
      ])

      let (records, token) = try await service.fetchAllRecordChanges()

      #expect(records.count == 5)
      #expect(token == "token-2")
    }

    @Test("fetchAllRecordChanges() uses final syncToken when moreComing transitions to false")
    internal func fetchAllRecordChangesFinalSyncToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceFetchChangesTests.makePaginatedService(pages: [
        (recordCount: 1, syncToken: "interim-token"),
        (recordCount: 1, syncToken: "final-token"),
      ])

      let (_, token) = try await service.fetchAllRecordChanges()

      #expect(token == "final-token")
    }

    @Test("fetchAllRecordChanges() handles moreComing=true with empty first page")
    internal func fetchAllRecordChangesEmptyFirstPage() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceFetchChangesTests.makePaginatedService(pages: [
        (recordCount: 0, syncToken: "token-1"),
        (recordCount: 3, syncToken: "token-2"),
      ])

      let (records, token) = try await service.fetchAllRecordChanges()

      #expect(records.count == 3)
      #expect(token == "token-2")
    }
  }
}

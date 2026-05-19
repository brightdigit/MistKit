//
//  CloudKitServiceTests.FetchChanges+SuccessCases.swift
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

internal import Foundation
internal import Testing

@testable import MistKit

extension CloudKitServiceTests.FetchChanges {
  @Suite("Success Cases")
  internal struct SuccessCases {
    @Test("fetchRecordChanges() returns records and sync token")
    internal func fetchRecordChangesReturnsRecordsAndToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.FetchChanges.makeSuccessfulService(
        recordCount: 3,
        syncToken: "new-token-123"
      )

      let result = try await service.fetchRecordChanges(
        database: .public(.prefers(.serverToServer))
      )

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
      let service = try await CloudKitServiceTests.FetchChanges.makeSuccessfulService(
        recordCount: 2,
        moreComing: true
      )

      let result = try await service.fetchRecordChanges(
        database: .public(.prefers(.serverToServer))
      )

      #expect(result.moreComing == true)
      #expect(result.records.count == 2)
    }

    @Test("fetchRecordChanges() works without sync token (initial fetch)")
    internal func fetchRecordChangesWorksWithoutSyncToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.FetchChanges.makeSuccessfulService()

      let result = try await service.fetchRecordChanges(
        syncToken: nil,
        database: .public(.prefers(.serverToServer))
      )

      #expect(result.records.isEmpty == false)
      #expect(result.syncToken != nil)
    }

    @Test("fetchRecordChanges() returns record names and types")
    internal func fetchRecordChangesReturnsRecordDetails() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.FetchChanges
        .makeSuccessfulService(
          recordCount: 2
        )

      let result = try await service.fetchRecordChanges(
        database: .public(.prefers(.serverToServer))
      )

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
      let service = try await CloudKitServiceTests.FetchChanges.makeSuccessfulService(
        recordCount: 3,
        moreComing: false,
        syncToken: "final-token"
      )

      let (records, token) = try await service.fetchAllRecordChanges(
        database: .public(.prefers(.serverToServer))
      )

      #expect(records.count == 3)
      #expect(token == "final-token")
    }

    @Test("fetchAllRecordChanges() accumulates records across two pages")
    internal func fetchAllRecordChangesMultiPage() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.FetchChanges.makePaginatedService(pages: [
        (recordCount: 3, syncToken: "token-1"),
        (recordCount: 2, syncToken: "token-2"),
      ])

      let (records, token) = try await service.fetchAllRecordChanges(
        database: .public(.prefers(.serverToServer))
      )

      #expect(records.count == 5)
      #expect(token == "token-2")
    }

    @Test("fetchAllRecordChanges() uses final syncToken when moreComing transitions to false")
    internal func fetchAllRecordChangesFinalSyncToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.FetchChanges.makePaginatedService(pages: [
        (recordCount: 1, syncToken: "interim-token"),
        (recordCount: 1, syncToken: "final-token"),
      ])

      let (_, token) = try await service.fetchAllRecordChanges(
        database: .public(.prefers(.serverToServer))
      )

      #expect(token == "final-token")
    }

    @Test("fetchRecordChanges() surfaces deleted records with deleted flag set")
    internal func fetchRecordChangesSurfacesDeletedRecords() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let responseProvider = ResponseProvider(
        defaultResponse: .fetchChangesResponseWithDeletedRecord()
      )
      let transport = MockTransport(responseProvider: responseProvider)
      let service = try CloudKitService(
        containerIdentifier: TestConstants.serviceContainerIdentifier,
        credentials: Credentials(apiAuth: APICredentials(apiToken: TestConstants.apiToken)),
        transport: transport
      )

      let result = try await service.fetchRecordChanges(
        database: .public(.prefers(.serverToServer))
      )

      #expect(result.records.count == 2)
      let deletedRecord = try #require(result.records.first { $0.recordName == "deleted-record-0" })
      #expect(deletedRecord.deleted == true)
      let liveRecord = try #require(result.records.first { $0.recordName == "live-record-1" })
      #expect(liveRecord.deleted == false)
    }
  }
}

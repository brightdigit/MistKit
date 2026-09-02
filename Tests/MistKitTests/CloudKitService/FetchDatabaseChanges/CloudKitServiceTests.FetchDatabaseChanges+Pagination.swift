//
//  CloudKitServiceTests.FetchDatabaseChanges+Pagination.swift
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

extension CloudKitServiceTests.FetchDatabaseChanges {
  @Suite("Pagination")
  internal struct Pagination {
    private typealias Harness = CloudKitServiceTests.FetchDatabaseChanges

    @Test("fetchAllDatabaseChanges() accumulates zones across pages")
    internal func accumulatesAcrossPages() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await Harness.makePaginatedService(pages: [
        (zoneCount: 2, syncToken: "token-1"),
        (zoneCount: 3, syncToken: "token-2"),
      ])

      let (zones, token) = try await service.fetchAllDatabaseChanges(database: .private)

      #expect(zones.count == 5)
      #expect(token == "token-2")
    }

    @Test("fetchAllDatabaseChanges() handles an empty first page with moreComing")
    internal func emptyFirstPage() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await Harness.makePaginatedService(pages: [
        (zoneCount: 0, syncToken: "token-1"),
        (zoneCount: 3, syncToken: "token-2"),
      ])

      let (zones, token) = try await service.fetchAllDatabaseChanges(database: .private)

      #expect(zones.count == 3)
      #expect(token == "token-2")
    }

    @Test("fetchAllDatabaseChanges() stops on a stuck token instead of looping")
    internal func stopsOnStuckToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Harness.makeStuckTokenService(syncToken: "stuck")

      let (zones, token) = try await service.fetchAllDatabaseChanges(
        syncToken: "stuck",
        database: .private
      )

      #expect(zones.isEmpty)
      #expect(token == "stuck")
    }

    @Test("fetchAllDatabaseChanges() throws zonePaginationLimitExceeded past maxPages")
    internal func throwsPastMaxPages() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      // Every page reports moreComing with a fresh token, so pagination only
      // ends at the maxPages ceiling.
      let provider = ResponseProvider(
        defaultResponse: try .successfulFetchDatabaseChangesResponse(
          zoneCount: 1,
          moreComing: true,
          syncToken: "token-a"
        )
      )
      for index in 0..<4 {
        await provider.enqueue(
          try .successfulFetchDatabaseChangesResponse(
            zoneCount: 1,
            moreComing: true,
            syncToken: "token-\(index)"
          ),
          for: "fetchDatabaseChanges"
        )
      }
      let service = try Harness.makeService(provider: provider)

      do {
        _ = try await service.fetchAllDatabaseChanges(maxPages: 2, database: .private)
        Issue.record("expected .zonePaginationLimitExceeded")
      } catch {
        guard case .zonePaginationLimitExceeded(let maxPages, let zones) = error else {
          Issue.record("expected .zonePaginationLimitExceeded, got \(error)")
          return
        }
        #expect(maxPages == 2)
        #expect(zones.count == 2)
      }
    }
  }
}

//
//  CloudKitService+RecordZoneChangesPagination.swift
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
internal import MistKitOpenAPI

extension CloudKitService {
  /// Fetch all record zone changes, handling per-zone pagination automatically.
  ///
  /// Convenience over
  /// ``fetchRecordZoneChanges(zones:reverse:desiredKeys:resultsLimit:desiredRecordTypes:database:)``.
  /// Because `changes/zone` paginates *per zone*, each round re-requests only
  /// the zones still reporting `moreComing`, carrying each zone's own returned
  /// sync token forward. Records for a zone are accumulated across rounds and
  /// merged into a single ``ZoneRecordChanges`` carrying that zone's final
  /// sync token.
  ///
  /// - Parameters:
  ///   - zones: The zones to fetch record changes from.
  ///   - reverse: Whether changes are returned in reverse order.
  ///   - desiredKeys: Field names limiting the fields returned per record.
  ///   - resultsLimit: Maximum number of records to fetch per request.
  ///   - desiredRecordTypes: Record-type names limiting the change feed.
  ///   - maxPages: Maximum number of rounds before throwing
  ///     ``CloudKitError/paginationLimitExceeded(maxPages:records:)``
  ///     (defaults to 1,000).
  ///   - database: The CloudKit database scope to query (defaults to `.private`).
  /// - Returns: One merged entry per originally-requested zone, in input order.
  /// - Throws: ``CloudKitError``. When `maxPages` is exceeded, throws
  ///   ``CloudKitError/paginationLimitExceeded(maxPages:records:)`` whose
  ///   `records` payload contains every record collected before the cap.
  ///
  /// - Warning: A zone that repeatedly reports `moreComing: true` with no
  ///   records and an unchanged sync token (stuck token) is dropped from the
  ///   next round rather than looping forever.
  /// - Note: Makes sequential requests with no backoff between rounds.
  public func fetchAllRecordZoneChanges(
    zones: [ZoneChangesRequest],
    reverse: Bool? = nil,
    desiredKeys: [String]? = nil,
    resultsLimit: Int? = nil,
    desiredRecordTypes: [String]? = nil,
    maxPages: Int = 1_000,
    database: Database = .private
  ) async throws(CloudKitError) -> RecordZoneChangesResult {
    var accumulator = ZoneChangesAccumulator(requested: zones)
    var pending = zones
    var pageCount = 0

    while !pending.isEmpty {
      guard pageCount < maxPages else {
        throw CloudKitError.paginationLimitExceeded(
          maxPages: maxPages,
          records: accumulator.allRecords
        )
      }

      do {
        try Task.checkCancellation()
      } catch {
        throw mapToCloudKitError(error, context: "fetchAllRecordZoneChanges")
      }

      let result = try await fetchRecordZoneChanges(
        zones: pending,
        reverse: reverse,
        desiredKeys: desiredKeys,
        resultsLimit: resultsLimit,
        desiredRecordTypes: desiredRecordTypes,
        database: database
      )

      pending = accumulator.merge(
        result, pending: pending, reverse: reverse,
        desiredKeys: desiredKeys, resultsLimit: resultsLimit,
        desiredRecordTypes: desiredRecordTypes)
      pageCount += 1
    }

    return accumulator.finish()
  }
}

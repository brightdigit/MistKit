//
//  CloudKitService+QueryPagination.swift
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

extension CloudKitService {
  /// Query all records, handling pagination automatically
  ///
  /// Convenience method that automatically fetches all matching records
  /// by following continuation markers and making multiple requests
  /// if needed.
  ///
  /// - Parameters:
  ///   - recordType: The type of records to query (must not be empty)
  ///   - filters: Optional array of filters to apply to the query
  ///   - sortBy: Optional array of sort descriptors
  ///   - pageSize: Maximum number of records per page
  ///     (1-200, defaults to `defaultQueryLimit`)
  ///   - desiredKeys: Optional array of field names to fetch
  ///   - maxPages: Maximum number of pages to fetch before throwing
  ///     `CloudKitError.paginationLimitExceeded` (defaults to 1,000)
  ///   - zoneID: Optional zone to query. When `nil` (the default) CloudKit
  ///     resolves the database's default zone (`_defaultZone`). Pass a
  ///     ``ZoneID`` to target a custom or shared zone.
  ///   - database: The CloudKit database scope to query (`.public`, `.private`, `.shared`)
  /// - Returns: Array of all matching records across all pages
  /// - Throws: `CloudKitError`. When `maxPages` is exceeded, throws
  ///   `.paginationLimitExceeded(maxPages:records:)` whose `records`
  ///   payload contains every record collected before the cap was hit,
  ///   so callers can resume or surface partial results.
  ///
  /// - Warning: Stops early if the server returns the same
  ///   continuation marker with no new records (stuck-marker
  ///   scenario).
  public func queryAllRecords(
    recordType: String,
    filters: [QueryFilter]? = nil,
    sortBy: [QuerySort]? = nil,
    pageSize: Int? = nil,
    desiredKeys: [String]? = nil,
    maxPages: Int = 1_000,
    zoneID: ZoneID? = nil,
    database: Database
  ) async throws(CloudKitError) -> [RecordInfo] {
    var allRecords: [RecordInfo] = []
    var currentMarker: String?
    var pageCount = 0

    repeat {
      guard pageCount < maxPages else {
        throw CloudKitError.paginationLimitExceeded(
          maxPages: maxPages,
          records: allRecords
        )
      }

      do {
        try Task.checkCancellation()
      } catch {
        throw mapToCloudKitError(error, context: "queryAllRecords")
      }

      let result: QueryResult = try await queryRecords(
        Query(recordType: recordType, filters: filters ?? [], sortBy: sortBy ?? []),
        limit: pageSize,
        desiredKeys: desiredKeys,
        continuationMarker: currentMarker,
        zoneID: zoneID,
        database: database
      )

      // Stuck-marker detection
      if result.records.isEmpty
        && result.continuationMarker != nil
        && result.continuationMarker == currentMarker
      {
        break
      }

      allRecords.append(contentsOf: result.records)
      currentMarker = result.continuationMarker
      pageCount += 1
    } while currentMarker != nil

    return allRecords
  }
}

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

import Foundation

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
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
  ///     `CloudKitError.invalidResponse` (defaults to 1,000)
  /// - Returns: Array of all matching records across all pages
  /// - Throws: CloudKitError if any page request fails
  ///
  /// - Warning: Stops early if the server returns the same
  ///   continuation marker with no new records (stuck-marker
  ///   scenario), or if the page count exceeds `maxPages`.
  public func queryAllRecords(
    recordType: String,
    filters: [QueryFilter]? = nil,
    sortBy: [QuerySort]? = nil,
    pageSize: Int? = nil,
    desiredKeys: [String]? = nil,
    maxPages: Int = 1_000,
    database: Database? = nil
  ) async throws(CloudKitError) -> [RecordInfo] {
    var allRecords: [RecordInfo] = []
    var currentMarker: String?
    var pageCount = 0

    repeat {
      guard pageCount < maxPages else {
        throw CloudKitError.paginationLimitExceeded(
          maxPages: maxPages,
          recordsCollected: allRecords.count
        )
      }

      do {
        try Task.checkCancellation()
      } catch {
        throw mapToCloudKitError(error, context: "queryAllRecords")
      }

      let result: QueryResult = try await queryRecords(
        recordType: recordType,
        filters: filters,
        sortBy: sortBy,
        limit: pageSize,
        desiredKeys: desiredKeys,
        continuationMarker: currentMarker,
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

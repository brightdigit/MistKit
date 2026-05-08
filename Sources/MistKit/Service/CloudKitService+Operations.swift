//
//  CloudKitService+Operations.swift
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
import OpenAPIRuntime

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

#if !os(WASI)
  import OpenAPIURLSession
#endif

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
  /// Query records from the default zone
  ///
  /// Queries CloudKit records with optional filtering and sorting.
  /// Supports all CloudKit filter operations (equals, comparisons,
  /// string matching, list operations) and field-based sorting.
  ///
  /// - Parameters:
  ///   - recordType: The type of records to query (must not be empty)
  ///   - filters: Optional array of filters to apply to the query
  ///   - sortBy: Optional array of sort descriptors
  ///   - limit: Maximum number of records to return
  ///     (1-200, defaults to `defaultQueryLimit`)
  ///   - desiredKeys: Optional array of field names to fetch
  /// - Returns: Array of matching records
  /// - Throws: CloudKitError if validation fails or the request fails
  ///
  /// # Example: Basic Query
  /// ```swift
  /// let articles = try await service.queryRecords(
  ///   recordType: "Article"
  /// )
  /// ```
  ///
  /// # Example: Query with Filters
  /// ```swift
  /// let recentArticles = try await service.queryRecords(
  ///   recordType: "Article",
  ///   filters: [
  ///     .greaterThan("publishedDate", .date(oneWeekAgo)),
  ///     .equals("status", .string("published"))
  ///   ],
  ///   limit: 50
  /// )
  /// ```
  ///
  /// # Example: Query with Sorting
  /// ```swift
  /// let sortedArticles = try await service.queryRecords(
  ///   recordType: "Article",
  ///   sortBy: [.descending("publishedDate")],
  ///   limit: 20
  /// )
  /// ```
  ///
  /// - Note: For large result sets, consider using pagination
  ///   with `continuationMarker` or `queryAllRecords`
  @available(
    *, deprecated,
    message:
      "Use queryRecords(...) -> QueryResult to handle pagination explicitly, or queryAllRecords(...) to auto-paginate."
  )
  public func queryRecords(
    recordType: String,
    filters: [QueryFilter]? = nil,
    sortBy: [QuerySort]? = nil,
    limit: Int? = nil,
    desiredKeys: [String]? = nil
  ) async throws(CloudKitError) -> [RecordInfo] {
    let result: QueryResult = try await queryRecords(
      recordType: recordType,
      filters: filters,
      sortBy: sortBy,
      limit: limit,
      desiredKeys: desiredKeys,
      continuationMarker: nil
    )
    return result.records
  }

  /// Query records from the default zone with pagination support
  ///
  /// Queries CloudKit records with optional filtering, sorting, and pagination.
  /// Returns a `QueryResult` containing both the matching records and
  /// a `continuationMarker` for fetching subsequent pages.
  ///
  /// - Parameters:
  ///   - recordType: The type of records to query (must not be empty)
  ///   - filters: Optional array of filters to apply to the query
  ///   - sortBy: Optional array of sort descriptors
  ///   - limit: Maximum number of records to return
  ///     (1-200, defaults to `defaultQueryLimit`)
  ///   - desiredKeys: Optional array of field names to fetch
  ///   - continuationMarker: Marker from a previous `QueryResult`
  ///     to fetch the next page of results
  /// - Returns: A `QueryResult` with matching records and an optional
  ///   continuation marker for the next page
  /// - Throws: CloudKitError if validation fails or the request fails
  ///
  /// # Example: Paginated Query
  /// ```swift
  /// var marker: String? = nil
  /// repeat {
  ///   let result: QueryResult = try await service.queryRecords(
  ///     recordType: "Article",
  ///     limit: 50,
  ///     continuationMarker: marker
  ///   )
  ///   process(result.records)
  ///   marker = result.continuationMarker
  /// } while marker != nil
  /// ```
  public func queryRecords(
    recordType: String,
    filters: [QueryFilter]? = nil,
    sortBy: [QuerySort]? = nil,
    limit: Int? = nil,
    desiredKeys: [String]? = nil,
    continuationMarker: String? = nil
  ) async throws(CloudKitError) -> QueryResult {
    let effectiveLimit = limit ?? defaultQueryLimit

    guard !recordType.isEmpty else {
      throw CloudKitError.httpErrorWithRawResponse(
        statusCode: 400,
        rawResponse: "recordType cannot be empty"
      )
    }

    guard effectiveLimit > 0 && effectiveLimit <= 200 else {
      throw CloudKitError.httpErrorWithRawResponse(
        statusCode: 400,
        rawResponse:
          "limit must be between 1 and 200, got \(effectiveLimit)"
      )
    }

    let componentsFilters = filters?.map {
      Components.Schemas.Filter(from: $0)
    }
    let componentsSorts = sortBy?.map {
      Components.Schemas.Sort(from: $0)
    }

    do {
      let response = try await client.queryRecords(
        .init(
          path: createQueryRecordsPath(
            containerIdentifier: containerIdentifier
          ),
          body: .json(
            .init(
              zoneID: .init(zoneName: "_defaultZone"),
              resultsLimit: effectiveLimit,
              query: .init(
                recordType: recordType,
                filterBy: componentsFilters,
                sortBy: componentsSorts
              ),
              desiredKeys: desiredKeys,
              continuationMarker: continuationMarker
            )
          )
        )
      )

      let recordsData: Components.Schemas.QueryResponse =
        try await responseProcessor.processQueryRecordsResponse(response)
      return QueryResult(from: recordsData)
    } catch {
      throw mapToCloudKitError(error, context: "queryRecords")
    }
  }

  /// Query all records, handling pagination automatically
  ///
  /// Convenience method that automatically fetches all matching records
  /// by following continuation markers and making multiple requests if needed.
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
  /// - Warning: Stops early if the server returns the same continuation
  ///   marker with no new records (stuck-marker scenario), or if
  ///   the page count exceeds `maxPages`.
  public func queryAllRecords(
    recordType: String,
    filters: [QueryFilter]? = nil,
    sortBy: [QuerySort]? = nil,
    pageSize: Int? = nil,
    desiredKeys: [String]? = nil,
    maxPages: Int = 1_000
  ) async throws(CloudKitError) -> [RecordInfo] {
    var allRecords: [RecordInfo] = []
    var currentMarker: String? = nil
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
        continuationMarker: currentMarker
      )

      // Stuck-marker detection
      if result.records.isEmpty && result.continuationMarker != nil
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

  /// Modify (create, update, delete) records
  @available(
    *, deprecated,
    message: "Use modifyRecords(_:) with RecordOperation in CloudKitService+WriteOperations instead"
  )
  internal func modifyRecords(
    operations: [Components.Schemas.RecordOperation],
    atomic: Bool = true
  ) async throws(CloudKitError) -> [RecordInfo] {
    do {
      let response = try await client.modifyRecords(
        .init(
          path: createModifyRecordsPath(
            containerIdentifier: containerIdentifier
          ),
          body: .json(
            .init(
              operations: operations,
              atomic: atomic
            )
          )
        )
      )

      let modifyData: Components.Schemas.ModifyResponse =
        try await responseProcessor.processModifyRecordsResponse(response)
      return modifyData.records?.compactMap { RecordInfo(from: $0) } ?? []
    } catch {
      throw mapToCloudKitError(error, context: "modifyRecords")
    }
  }

  /// Lookup records by record names
  public func lookupRecords(
    recordNames: [String],
    desiredKeys: [String]? = nil
  ) async throws(CloudKitError) -> [RecordInfo] {
    do {
      let response = try await client.lookupRecords(
        .init(
          path: createLookupRecordsPath(
            containerIdentifier: containerIdentifier
          ),
          body: .json(
            .init(
              records: recordNames.map { recordName in
                .init(
                  recordName: recordName,
                  desiredKeys: desiredKeys
                )
              }
            )
          )
        )
      )

      let lookupData: Components.Schemas.LookupResponse =
        try await responseProcessor.processLookupRecordsResponse(response)
      return lookupData.records?.compactMap { RecordInfo(from: $0) } ?? []
    } catch {
      throw mapToCloudKitError(error, context: "lookupRecords")
    }
  }
}

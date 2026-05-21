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

internal import Foundation
internal import MistKitOpenAPI
internal import OpenAPIRuntime

#if canImport(FoundationNetworking)
  internal import FoundationNetworking
#endif

#if !os(WASI)
  internal import OpenAPIURLSession
#endif

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
  ///   - database: The CloudKit database scope to query (`.public`, `.private`, `.shared`)
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
    message: "Use queryRecords -> QueryResult for pagination, or queryAllRecords to auto-paginate."
  )
  public func queryRecords(
    recordType: String,
    filters: [QueryFilter]? = nil,
    sortBy: [QuerySort]? = nil,
    limit: Int? = nil,
    desiredKeys: [String]? = nil,
    database: Database
  ) async throws(CloudKitError) -> [RecordInfo] {
    let result: QueryResult = try await queryRecords(
      recordType: recordType,
      filters: filters,
      sortBy: sortBy,
      limit: limit,
      desiredKeys: desiredKeys,
      continuationMarker: nil,
      database: database
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
  ///   - database: The CloudKit database scope to query (`.public`, `.private`, `.shared`)
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
    continuationMarker: String? = nil,
    database: Database
  ) async throws(CloudKitError) -> QueryResult {
    let effectiveLimit = limit ?? defaultQueryLimit

    let componentsFilters = filters?.map {
      Components.Schemas.Filter(from: $0)
    }
    let componentsSorts = sortBy?.map {
      Components.Schemas.Sort(from: $0)
    }

    do {
      let client = try self.client(for: database)
      let response = try await client.queryRecords(
        .init(
          path: Operations.queryRecords.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: environment,
            database: database
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
      return try QueryResult(from: recordsData)
    } catch {
      throw mapToCloudKitError(error, context: "queryRecords")
    }
  }
}

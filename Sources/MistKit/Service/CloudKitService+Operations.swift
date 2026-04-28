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
  public func queryRecords(
    recordType: String,
    filters: [QueryFilter]? = nil,
    sortBy: [QuerySort]? = nil,
    limit: Int? = nil,
    desiredKeys: [String]? = nil
  ) async throws(CloudKitError) -> [RecordInfo] {
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
              desiredKeys: desiredKeys
            )
          )
        )
      )

      let recordsData: Components.Schemas.QueryResponse =
        try await responseProcessor.processQueryRecordsResponse(response)
      return recordsData.records?.compactMap { RecordInfo(from: $0) } ?? []
    } catch {
      throw mapToCloudKitError(error, context: "queryRecords")
    }
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

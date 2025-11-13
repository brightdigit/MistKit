//
//  CloudKitService+Operations.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
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
import OpenAPIURLSession

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
  /// Fetch current user information
  public func fetchCurrentUser() async throws(CloudKitError) -> UserInfo {
    do {
      let response = try await client.getCurrentUser(
        .init(
          path: createGetCurrentUserPath(containerIdentifier: containerIdentifier)
        )
      )

      let userData: Components.Schemas.UserResponse =
        try await responseProcessor.processGetCurrentUserResponse(response)
      return UserInfo(from: userData)
    } catch let cloudKitError as CloudKitError {
      throw cloudKitError
    } catch let decodingError as DecodingError {
      MistKitLogger.logError(
        "JSON decoding failed in fetchCurrentUser: \(decodingError)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )
      throw CloudKitError.decodingError(decodingError)
    } catch let urlError as URLError {
      MistKitLogger.logError(
        "Network error in fetchCurrentUser: \(urlError)",
        logger: MistKitLogger.network,
        shouldRedact: false
      )
      throw CloudKitError.networkError(urlError)
    } catch {
      MistKitLogger.logError(
        "Unexpected error in fetchCurrentUser: \(error)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )
      throw CloudKitError.underlyingError(error)
    }
  }

  /// List zones in the user's private database
  public func listZones() async throws(CloudKitError) -> [ZoneInfo] {
    do {
      let response = try await client.listZones(
        .init(
          path: createListZonesPath(containerIdentifier: containerIdentifier)
        )
      )

      let zonesData: Components.Schemas.ZonesListResponse =
        try await responseProcessor.processListZonesResponse(response)
      return zonesData.zones?.compactMap { zone in
        guard let zoneID = zone.zoneID else {
          return nil
        }
        return ZoneInfo(
          zoneName: zoneID.zoneName ?? "Unknown",
          ownerRecordName: zoneID.ownerName,
          capabilities: []
        )
      } ?? []
    } catch let cloudKitError as CloudKitError {
      throw cloudKitError
    } catch let decodingError as DecodingError {
      MistKitLogger.logError(
        "JSON decoding failed in listZones: \(decodingError)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )
      throw CloudKitError.decodingError(decodingError)
    } catch let urlError as URLError {
      MistKitLogger.logError(
        "Network error in listZones: \(urlError)",
        logger: MistKitLogger.network,
        shouldRedact: false
      )
      throw CloudKitError.networkError(urlError)
    } catch {
      MistKitLogger.logError(
        "Unexpected error in listZones: \(error)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )
      throw CloudKitError.underlyingError(error)
    }
  }

  /// Query records from the default zone
  ///
  /// Queries CloudKit records with optional filtering and sorting. Supports all CloudKit
  /// filter operations (equals, comparisons, string matching, list operations) and field-based sorting.
  ///
  /// - Parameters:
  ///   - recordType: The type of records to query (must not be empty)
  ///   - filters: Optional array of filters to apply to the query
  ///   - sortBy: Optional array of sort descriptors
  ///   - limit: Maximum number of records to return (1-200, default: 10)
  ///   - desiredKeys: Optional array of field names to fetch
  /// - Returns: Array of matching records
  /// - Throws: CloudKitError if validation fails or the request fails
  ///
  /// # Example: Basic Query
  /// ```swift
  /// // Query all articles
  /// let articles = try await service.queryRecords(
  ///   recordType: "Article"
  /// )
  /// ```
  ///
  /// # Example: Query with Filters
  /// ```swift
  /// // Query published articles from the last week
  /// let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
  /// let recentArticles = try await service.queryRecords(
  ///   recordType: "Article",
  ///   filters: [
  ///     .greaterThan("publishedDate", .date(oneWeekAgo)),
  ///     .equals("status", .string("published")),
  ///     .equals("language", .string("en"))
  ///   ],
  ///   limit: 50
  /// )
  /// ```
  ///
  /// # Example: Query with Sorting
  /// ```swift
  /// // Query articles sorted by date (newest first)
  /// let sortedArticles = try await service.queryRecords(
  ///   recordType: "Article",
  ///   sortBy: [.descending("publishedDate")],
  ///   limit: 20
  /// )
  /// ```
  ///
  /// # Example: Complex Query with String Matching
  /// ```swift
  /// // Search for articles with titles containing "Swift"
  /// let swiftArticles = try await service.queryRecords(
  ///   recordType: "Article",
  ///   filters: [
  ///     .contains("title", .string("Swift")),
  ///     .notEquals("status", .string("draft"))
  ///   ],
  ///   sortBy: [.descending("publishedDate")],
  ///   desiredKeys: ["title", "publishedDate", "author"]
  /// )
  /// ```
  ///
  /// # Example: List Operations
  /// ```swift
  /// // Query articles with specific tags
  /// let taggedArticles = try await service.queryRecords(
  ///   recordType: "Article",
  ///   filters: [
  ///     .in("category", [.string("Technology"), .string("Programming")]),
  ///     .greaterThanOrEquals("viewCount", .int64(1000))
  ///   ]
  /// )
  /// ```
  ///
  /// # Available Filter Operations
  /// - Equality: `.equals()`, `.notEquals()`
  /// - Comparison: `.lessThan()`, `.lessThanOrEquals()`, `.greaterThan()`, `.greaterThanOrEquals()`
  /// - String: `.beginsWith()`, `.contains()`, `.endsWith()`
  /// - List: `.in()`, `.notIn()`
  /// - Negation: `.not()`
  ///
  /// - Note: For large result sets, consider using pagination (see GitHub issue #145)
  /// - Note: To query custom zones, see GitHub issue #146
  public func queryRecords(
    recordType: String,
    filters: [QueryFilter]? = nil,
    sortBy: [QuerySort]? = nil,
    limit: Int = 10,
    desiredKeys: [String]? = nil
  ) async throws(CloudKitError) -> [RecordInfo] {
    // Validate input parameters
    guard !recordType.isEmpty else {
      throw CloudKitError.httpErrorWithRawResponse(
        statusCode: 400,
        rawResponse: "recordType cannot be empty"
      )
    }

    guard limit > 0 && limit <= 200 else {
      throw CloudKitError.httpErrorWithRawResponse(
        statusCode: 400,
        rawResponse: "limit must be between 1 and 200, got \(limit)"
      )
    }

    let componentsFilters = filters?.map { $0.toComponentsFilter() }
    let componentsSorts = sortBy?.map { $0.toComponentsSort() }

    do {
      let response = try await client.queryRecords(
        .init(
          path: createQueryRecordsPath(containerIdentifier: containerIdentifier),
          body: .json(
            .init(
              zoneID: .init(zoneName: "_defaultZone"),
              resultsLimit: limit,
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
    } catch let cloudKitError as CloudKitError {
      throw cloudKitError
    } catch let decodingError as DecodingError {
      // Log detailed decoding error information
      MistKitLogger.logError(
        "JSON decoding failed in queryRecords: \(decodingError)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )

      // Log detailed context based on error type
      switch decodingError {
      case .keyNotFound(let key, let context):
        MistKitLogger.logDebug(
          "Missing key: \(key), Context: \(context.debugDescription), Coding path: \(context.codingPath)",
          logger: MistKitLogger.api,
          shouldRedact: false
        )
      case .typeMismatch(let type, let context):
        MistKitLogger.logDebug(
          "Type mismatch: expected \(type), Context: \(context.debugDescription), Coding path: \(context.codingPath)",
          logger: MistKitLogger.api,
          shouldRedact: false
        )
      case .valueNotFound(let type, let context):
        MistKitLogger.logDebug(
          "Value not found: expected \(type), Context: \(context.debugDescription), Coding path: \(context.codingPath)",
          logger: MistKitLogger.api,
          shouldRedact: false
        )
      case .dataCorrupted(let context):
        MistKitLogger.logDebug(
          "Data corrupted, Context: \(context.debugDescription), Coding path: \(context.codingPath)",
          logger: MistKitLogger.api,
          shouldRedact: false
        )
      @unknown default:
        MistKitLogger.logDebug(
          "Unknown decoding error type",
          logger: MistKitLogger.api,
          shouldRedact: false
        )
      }

      throw CloudKitError.decodingError(decodingError)
    } catch let urlError as URLError {
      // Log network error information
      MistKitLogger.logError(
        "Network error in queryRecords: \(urlError)",
        logger: MistKitLogger.network,
        shouldRedact: false
      )

      throw CloudKitError.networkError(urlError)
    } catch {
      // Log unexpected errors
      MistKitLogger.logError(
        "Unexpected error in queryRecords: \(error)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )

      // Log additional debugging details
      MistKitLogger.logDebug(
        "Error type: \(type(of: error)), Description: \(String(reflecting: error))",
        logger: MistKitLogger.api,
        shouldRedact: false
      )

      throw CloudKitError.underlyingError(error)
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
          path: createModifyRecordsPath(containerIdentifier: containerIdentifier),
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
    } catch let cloudKitError as CloudKitError {
      throw cloudKitError
    } catch let decodingError as DecodingError {
      MistKitLogger.logError(
        "JSON decoding failed in modifyRecords: \(decodingError)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )
      throw CloudKitError.decodingError(decodingError)
    } catch let urlError as URLError {
      MistKitLogger.logError(
        "Network error in modifyRecords: \(urlError)",
        logger: MistKitLogger.network,
        shouldRedact: false
      )
      throw CloudKitError.networkError(urlError)
    } catch {
      MistKitLogger.logError(
        "Unexpected error in modifyRecords: \(error)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )
      throw CloudKitError.underlyingError(error)
    }
  }

  /// Lookup records by record names
  internal func lookupRecords(
    recordNames: [String],
    desiredKeys: [String]? = nil
  ) async throws(CloudKitError) -> [RecordInfo] {
    do {
      let response = try await client.lookupRecords(
        .init(
          path: createLookupRecordsPath(containerIdentifier: containerIdentifier),
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
    } catch let cloudKitError as CloudKitError {
      throw cloudKitError
    } catch let decodingError as DecodingError {
      MistKitLogger.logError(
        "JSON decoding failed in lookupRecords: \(decodingError)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )
      throw CloudKitError.decodingError(decodingError)
    } catch let urlError as URLError {
      MistKitLogger.logError(
        "Network error in lookupRecords: \(urlError)",
        logger: MistKitLogger.network,
        shouldRedact: false
      )
      throw CloudKitError.networkError(urlError)
    } catch {
      MistKitLogger.logError(
        "Unexpected error in lookupRecords: \(error)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )
      throw CloudKitError.underlyingError(error)
    }
  }
}

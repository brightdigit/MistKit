//
//  CloudKitService+SyncOperations.swift
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
  /// Fetch record changes since a sync token
  ///
  /// Retrieves all records that have changed (created, updated, or deleted)
  /// since the provided sync token. Use this for efficient incremental sync
  /// operations rather than repeatedly querying all records.
  ///
  /// - Parameters:
  ///   - zoneID: Optional zone to fetch changes from
  ///     (defaults to _defaultZone)
  ///   - syncToken: Optional token from previous fetch (nil = initial fetch)
  ///   - resultsLimit: Optional maximum number of records (1-200)
  /// - Returns: RecordChangesResult containing changed records
  ///   and new sync token
  /// - Throws: CloudKitError if the fetch fails
  ///
  /// Example - Initial Sync:
  /// ```swift
  /// let result = try await service.fetchRecordChanges()
  /// // Store result.syncToken for next fetch
  /// processRecords(result.records)
  /// ```
  ///
  /// Example - Incremental Sync:
  /// ```swift
  /// let result = try await service.fetchRecordChanges(
  ///   syncToken: previousToken
  /// )
  /// if result.moreComing {
  ///   // More changes available, fetch again with new token
  ///   let next = try await service.fetchRecordChanges(
  ///     syncToken: result.syncToken
  ///   )
  /// }
  /// ```
  ///
  /// - Note: If moreComing is true, call again with the returned syncToken
  ///         to fetch remaining changes
  public func fetchRecordChanges(
    zoneID: ZoneID? = nil,
    syncToken: String? = nil,
    resultsLimit: Int? = nil
  ) async throws(CloudKitError) -> RecordChangesResult {
    if let limit = resultsLimit {
      guard limit > 0 && limit <= 200 else {
        throw CloudKitError.httpErrorWithRawResponse(
          statusCode: 400,
          rawResponse:
            "resultsLimit must be between 1 and 200, got \(limit)"
        )
      }
    }

    let effectiveZoneID = zoneID ?? .defaultZone

    do {
      let response = try await client.fetchRecordChanges(
        .init(
          path: createFetchRecordChangesPath(
            containerIdentifier: containerIdentifier
          ),
          body: .json(
            .init(
              zoneID: Components.Schemas.ZoneID(from: effectiveZoneID),
              syncToken: syncToken,
              resultsLimit: resultsLimit
            )
          )
        )
      )

      let changesData: Components.Schemas.ChangesResponse =
        try await responseProcessor.processFetchRecordChangesResponse(
          response
        )

      return RecordChangesResult(from: changesData)
    } catch {
      throw mapToCloudKitError(error, context: "fetchRecordChanges")
    }
  }

  /// Fetch all record changes, handling pagination automatically
  ///
  /// Convenience method that automatically fetches all available changes
  /// by following the moreComing flag and making multiple requests if needed.
  ///
  /// - Parameters:
  ///   - zoneID: Optional zone to fetch changes from
  ///     (defaults to _defaultZone)
  ///   - syncToken: Optional token from previous fetch (nil = initial fetch)
  ///   - resultsLimit: Optional maximum records per request (1-200)
  /// - Returns: Array of all changed records and final sync token
  /// - Throws: CloudKitError if any fetch fails
  ///
  /// Example:
  /// ```swift
  /// let (records, newToken) = try await service.fetchAllRecordChanges(
  ///   syncToken: lastSyncToken
  /// )
  /// // Process all records
  /// processRecords(records)
  /// // Store newToken for next sync
  /// ```
  ///
  /// - Warning: For zones with many changes, this may make multiple requests
  ///           and return a large array. Consider using fetchRecordChanges()
  ///           with manual pagination for better memory control.
  /// - Note: Makes sequential requests with no backoff or cooperative
  ///         cancellation between pages. For fine-grained control,
  ///         use `fetchRecordChanges(syncToken:)` directly.
  public func fetchAllRecordChanges(
    zoneID: ZoneID? = nil,
    syncToken: String? = nil,
    resultsLimit: Int? = nil
  ) async throws(CloudKitError) -> (records: [RecordInfo], syncToken: String?) {
    var allRecords: [RecordInfo] = []
    var currentToken = syncToken
    var moreComing = true

    while moreComing {
      let result = try await fetchRecordChanges(
        zoneID: zoneID,
        syncToken: currentToken,
        resultsLimit: resultsLimit
      )

      allRecords.append(contentsOf: result.records)
      currentToken = result.syncToken
      moreComing = result.moreComing
    }

    return (allRecords, currentToken)
  }
}

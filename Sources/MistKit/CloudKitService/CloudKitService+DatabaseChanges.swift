//
//  CloudKitService+DatabaseChanges.swift
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
  /// Fetch the record zones that changed since a sync token.
  ///
  /// Calls `changes/database` (Fetching Database Changes), the current
  /// replacement for the deprecated `zones/changes` operation wrapped by
  /// ``fetchZoneChanges(syncToken:database:)``. It reports *which zones*
  /// changed; follow up with
  /// ``fetchRecordZoneChanges(zones:reverse:desiredKeys:resultsLimit:desiredRecordTypes:database:)``
  /// to fetch the record changes inside each returned zone.
  ///
  /// - Parameters:
  ///   - syncToken: Token from a previous fetch (`nil` = initial fetch).
  ///   - resultsLimit: Optional maximum number of zone changes to return.
  ///   - database: The CloudKit database scope to query (defaults to `.private`).
  /// - Returns: ``DatabaseChangesResult`` containing the per-zone outcomes and
  ///   a new sync token.
  /// - Throws: ``CloudKitError`` if the fetch fails.
  ///
  /// Example:
  /// ```swift
  /// let result = try await service.fetchDatabaseChanges()
  /// for zone in result.changedZones {
  ///   print("changed: \(zone.zoneName)")
  /// }
  /// // Store result.syncToken for the next fetch.
  /// ```
  ///
  /// - Note: Per-zone failures are surfaced as ``ZoneChangeResult/failure(_:)``
  ///   entries in ``DatabaseChangesResult/zones`` rather than thrown, so one
  ///   bad zone never discards the zones that succeeded.
  public func fetchDatabaseChanges(
    syncToken: String? = nil,
    resultsLimit: Int? = nil,
    database: Database = .private
  ) async throws(CloudKitError) -> DatabaseChangesResult {
    do {
      let client = try self.client(for: database)
      let response = try await client.fetchDatabaseChanges(
        .init(
          path: Operations.fetchDatabaseChanges.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: environment,
            database: database
          ),
          body: .json(
            .init(
              syncToken: syncToken,
              resultsLimit: resultsLimit
            )
          )
        )
      )

      let changesData: Components.Schemas.DatabaseChangesResponse =
        try await responseProcessor.processFetchDatabaseChangesResponse(response)

      return try DatabaseChangesResult(from: changesData)
    } catch {
      throw mapToCloudKitError(error, context: "fetchDatabaseChanges")
    }
  }

  /// Fetch all database changes, handling pagination automatically.
  ///
  /// Convenience over ``fetchDatabaseChanges(syncToken:resultsLimit:database:)``
  /// that follows the `moreComing` flag until the server reports no more
  /// changes, concatenating the per-zone outcomes in the order received.
  ///
  /// - Parameters:
  ///   - syncToken: Token from a previous fetch (`nil` = initial fetch).
  ///   - resultsLimit: Optional maximum number of zone changes per request.
  ///   - maxPages: Maximum number of pages to fetch before throwing
  ///     ``CloudKitError/zonePaginationLimitExceeded(maxPages:zones:)``
  ///     (defaults to 1,000).
  ///   - database: The CloudKit database scope to query (defaults to `.private`).
  /// - Returns: The accumulated per-zone outcomes and the final sync token.
  /// - Throws: ``CloudKitError``. When `maxPages` is exceeded, throws
  ///   ``CloudKitError/zonePaginationLimitExceeded(maxPages:zones:)`` whose
  ///   `zones` payload contains every *successfully changed* zone collected
  ///   before the cap was hit.
  ///
  /// - Warning: Stops early if the server repeatedly returns `moreComing: true`
  ///   with no zones and an unchanged sync token (stuck-token scenario).
  /// - Note: Makes sequential requests with no backoff between pages.
  public func fetchAllDatabaseChanges(
    syncToken: String? = nil,
    resultsLimit: Int? = nil,
    maxPages: Int = 1_000,
    database: Database = .private
  ) async throws(CloudKitError) -> (zones: [ZoneChangeResult], syncToken: String?) {
    var allZones: [ZoneChangeResult] = []
    var currentToken = syncToken
    var moreComing = false
    var pageCount = 0

    repeat {
      guard pageCount < maxPages else {
        throw CloudKitError.zonePaginationLimitExceeded(
          maxPages: maxPages,
          zones: allZones.compactMap { result in
            guard case .success(let zone) = result else { return nil }
            return zone
          }
        )
      }

      do {
        try Task.checkCancellation()
      } catch {
        throw mapToCloudKitError(error, context: "fetchAllDatabaseChanges")
      }

      let result = try await fetchDatabaseChanges(
        syncToken: currentToken,
        resultsLimit: resultsLimit,
        database: database
      )

      // Stuck-token detection
      if result.zones.isEmpty && result.moreComing && result.syncToken == currentToken {
        break
      }

      if result.moreComing && result.syncToken == nil {
        throw CloudKitError.invalidResponse
      }

      allZones.append(contentsOf: result.zones)
      currentToken = result.syncToken
      moreComing = result.moreComing
      pageCount += 1
    } while moreComing

    return (allZones, currentToken)
  }
}

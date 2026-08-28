//
//  CloudKitService+RecordZoneChanges.swift
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
  /// Fetch the records that changed within one or more record zones.
  ///
  /// Calls `changes/zone` (Fetching Record Zone Changes). Typically paired with
  /// ``fetchDatabaseChanges(syncToken:resultsLimit:database:)``, which reports
  /// *which* zones changed; this operation fetches the record changes inside
  /// them. Intended for custom zones.
  ///
  /// Each zone paginates independently: the response carries a sync token and
  /// `moreComing` flag per zone, not one for the whole request.
  ///
  /// - Parameters:
  ///   - zones: The zones to fetch record changes from. Per-zone values
  ///     override the request-level values below.
  ///   - reverse: Whether changes are returned in reverse order.
  ///   - desiredKeys: Field names limiting the fields returned per record.
  ///   - resultsLimit: Maximum number of records to fetch.
  ///   - desiredRecordTypes: Record-type names limiting the change feed.
  ///   - database: The CloudKit database scope to query (defaults to `.private`).
  /// - Returns: ``RecordZoneChangesResult`` with one entry per requested zone.
  /// - Throws: ``CloudKitError`` if the fetch fails.
  ///
  /// Example:
  /// ```swift
  /// let database = try await service.fetchDatabaseChanges()
  /// let result = try await service.fetchRecordZoneChanges(
  ///   zones: database.changedZones.map {
  ///     ZoneChangesRequest(zoneID: ZoneID(zoneName: $0.zoneName))
  ///   }
  /// )
  /// for change in result.changes {
  ///   print("\(change.zone.zoneName): \(change.records.count) changed")
  /// }
  /// ```
  ///
  /// - Note: Per-zone failures are surfaced as
  ///   ``ZoneRecordChangesResult/failure(_:)`` entries rather than thrown.
  public func fetchRecordZoneChanges(
    zones: [ZoneChangesRequest],
    reverse: Bool? = nil,
    desiredKeys: [String]? = nil,
    resultsLimit: Int? = nil,
    desiredRecordTypes: [String]? = nil,
    database: Database = .private
  ) async throws(CloudKitError) -> RecordZoneChangesResult {
    do {
      let client = try self.client(for: database)
      let response = try await client.fetchRecordZoneChanges(
        .init(
          path: Operations.fetchRecordZoneChanges.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: environment,
            database: database
          ),
          body: .json(
            .init(
              zones: zones.map {
                Components.Schemas.RecordZoneChangesRequestZone(from: $0)
              },
              reverse: reverse,
              desiredKeys: desiredKeys,
              resultsLimit: resultsLimit,
              desiredRecordTypes: desiredRecordTypes
            )
          )
        )
      )

      let changesData: Components.Schemas.RecordZoneChangesResponse =
        try await responseProcessor.processFetchRecordZoneChangesResponse(response)

      return try RecordZoneChangesResult(from: changesData)
    } catch {
      throw mapToCloudKitError(error, context: "fetchRecordZoneChanges")
    }
  }
}

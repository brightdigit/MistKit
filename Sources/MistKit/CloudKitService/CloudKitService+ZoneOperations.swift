//
//  CloudKitService+ZoneOperations.swift
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
internal import MistKitOpenAPI
import OpenAPIRuntime

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

#if !os(WASI)
  import OpenAPIURLSession
#endif

extension CloudKitService {
  /// List zones in the target database.
  ///
  /// > Note: The default is `.private` because the public database only
  /// > contains the default zone (`_defaultZone`); listing zones against
  /// > `.public` is degenerate. Pass `.shared` for the shared database.
  public func listZones(
    database: Database = .private
  ) async throws(CloudKitError) -> [ZoneInfo] {
    do {
      let client = try self.client(for: database)
      let response = try await client.listZones(
        .init(
          path: Operations.listZones.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: environment,
            database: database
          )
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
    } catch {
      throw mapToCloudKitError(error, context: "listZones")
    }
  }

  /// Lookup specific zones by their IDs
  ///
  /// Fetches detailed information about multiple zones in a single request.
  /// Unlike listZones which returns all zones, this operation retrieves
  /// specific zones identified by their zone IDs.
  ///
  /// - Parameters:
  ///   - zoneIDs: Array of zone identifiers to lookup
  ///   - database: The CloudKit database scope to query (defaults to `.private`)
  /// - Returns: Array of ZoneInfo objects for the requested zones
  /// - Throws: CloudKitError if the lookup fails
  ///
  /// Example:
  /// ```swift
  /// let zones = try await service.lookupZones(
  ///   zoneIDs: [
  ///     ZoneID(zoneName: "Articles", ownerName: nil),
  ///     ZoneID(zoneName: "Images", ownerName: nil)
  ///   ]
  /// )
  /// ```
  public func lookupZones(
    zoneIDs: [ZoneID],
    database: Database = .private
  ) async throws(CloudKitError) -> [ZoneInfo] {
    guard !zoneIDs.isEmpty else {
      throw CloudKitError.httpErrorWithRawResponse(
        statusCode: 400,
        rawResponse: "zoneIDs cannot be empty"
      )
    }
    guard zoneIDs.allSatisfy({ !$0.zoneName.isEmpty }) else {
      throw CloudKitError.httpErrorWithRawResponse(
        statusCode: 400,
        rawResponse: "zoneIDs contains a zone with an empty zoneName"
      )
    }

    do {
      let client = try self.client(for: database)
      let response = try await client.lookupZones(
        .init(
          path: Operations.lookupZones.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: environment,
            database: database
          ),
          body: .json(
            .init(
              zones: zoneIDs.map { Components.Schemas.ZoneID(from: $0) }
            )
          )
        )
      )

      let zonesData: Components.Schemas.ZonesLookupResponse =
        try await responseProcessor.processLookupZonesResponse(response)

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
    } catch {
      throw mapToCloudKitError(error, context: "lookupZones")
    }
  }

  /// Fetch zone changes since a sync token
  ///
  /// Retrieves all zones that have changed since the provided sync token.
  /// Use this for efficient incremental sync at the zone level.
  ///
  /// - Parameters:
  ///   - syncToken: Optional token from previous fetch (nil = initial fetch)
  ///   - database: The CloudKit database scope to query (defaults to `.private`)
  /// - Returns: ZoneChangesResult containing changed zones and new sync token
  /// - Throws: CloudKitError if the fetch fails
  ///
  /// Example - Initial Sync:
  /// ```swift
  /// let result = try await service.fetchZoneChanges()
  /// // Store result.syncToken for next fetch
  /// processZones(result.zones)
  /// ```
  ///
  /// Example - Incremental Sync:
  /// ```swift
  /// let result = try await service.fetchZoneChanges(
  ///   syncToken: previousToken
  /// )
  /// ```
  public func fetchZoneChanges(
    syncToken: String? = nil,
    database: Database = .private
  ) async throws(CloudKitError) -> ZoneChangesResult {
    do {
      let client = try self.client(for: database)
      let response = try await client.fetchZoneChanges(
        .init(
          path: Operations.fetchZoneChanges.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: environment,
            database: database
          ),
          body: .json(
            .init(
              syncToken: syncToken
            )
          )
        )
      )

      let changesData: Components.Schemas.ZoneChangesResponse =
        try await responseProcessor.processFetchZoneChangesResponse(response)

      return ZoneChangesResult(from: changesData)
    } catch {
      throw mapToCloudKitError(error, context: "fetchZoneChanges")
    }
  }
}

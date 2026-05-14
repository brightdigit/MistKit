//
//  CloudKitService+ModifyZones.swift
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
  /// Create or delete zones in the target database.
  ///
  /// CloudKit's `zones/modify` endpoint is only supported on the `.private`
  /// and `.shared` databases — `.public` has only `_defaultZone`, so any
  /// modify against it is rejected here without a network round-trip.
  ///
  /// - Parameters:
  ///   - operations: Non-empty array of create/delete operations. Each
  ///     operation's `ZoneID` must have a non-empty `zoneName`.
  ///   - database: Target database. Must not be `.public`.
  /// - Returns: Array of `ZoneInfo` for the zones returned by the server.
  /// - Throws: `CloudKitError` if validation fails or the request fails.
  ///
  /// Example - Create and delete in one batch:
  /// ```swift
  /// let zones = try await service.modifyZones(
  ///   [
  ///     .create(ZoneID(zoneName: "Articles")),
  ///     .delete(ZoneID(zoneName: "Archive"))
  ///   ],
  ///   database: .private
  /// )
  /// ```
  public func modifyZones(
    _ operations: [ZoneOperation],
    database: Database
  ) async throws(CloudKitError) -> [ZoneInfo] {
    guard !operations.isEmpty else {
      throw CloudKitError.httpErrorWithRawResponse(
        statusCode: 400,
        rawResponse: "operations cannot be empty"
      )
    }
    guard operations.allSatisfy({ !$0.zoneID.zoneName.isEmpty }) else {
      throw CloudKitError.httpErrorWithRawResponse(
        statusCode: 400,
        rawResponse: "operations contains a zone with an empty zoneName"
      )
    }
    if case .public = database {
      throw CloudKitError.httpErrorWithRawResponse(
        statusCode: 400,
        rawResponse: "modifyZones is not supported on the public database"
      )
    }

    do {
      let client = try self.client(for: database)
      let response = try await client.modifyZones(
        .init(
          path: Operations.modifyZones.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: environment,
            database: database
          ),
          body: .json(
            .init(
              operations: operations.map { Components.Schemas.ZoneOperation(from: $0) }
            )
          )
        )
      )

      let zonesData: Components.Schemas.ZonesModifyResponse =
        try await responseProcessor.processModifyZonesResponse(response)

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
      throw mapToCloudKitError(error, context: "modifyZones")
    }
  }
}

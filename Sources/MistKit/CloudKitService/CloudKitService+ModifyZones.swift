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
  /// Create or delete zones in the target database.
  ///
  /// CloudKit's `zones/modify` endpoint is only supported on the `.private`
  /// and `.shared` databases — `.public` has only `_defaultZone`, so any
  /// modify against it is rejected here without a network round-trip.
  ///
  /// `zones/modify` is a batch endpoint whose realistic failure mode is
  /// *partial* — creating five zones where one already exists, or deleting
  /// zones where one is missing. CloudKit reports those inline in the 200
  /// response, so each entry is a ``ZoneChangeResult``: `.success` for a zone
  /// the server returned, `.failure` (a ``ZoneOperationFailure`` carrying the
  /// zone name, `serverErrorCode` and `reason`) for one it rejected. Use the
  /// `zones` / `failures` array conveniences to split them, or
  /// ``OperationResult/get()`` to rethrow a failure.
  ///
  /// - Parameters:
  ///   - operations: Non-empty array of create/delete operations. Each
  ///     operation's `ZoneID` must have a non-empty `zoneName`.
  ///   - database: Target database. Must not be `.public`.
  /// - Returns: A ``ZoneChangeResult`` per entry the server returned, in
  ///   response order.
  /// - Throws: `CloudKitError` if validation fails or the request fails.
  ///
  /// Example - Create and delete in one batch:
  /// ```swift
  /// let results = try await service.modifyZones(
  ///   [
  ///     .create(ZoneID(zoneName: "Articles")),
  ///     .delete(ZoneID(zoneName: "Archive"))
  ///   ],
  ///   database: .private
  /// )
  /// for failure in results.failures {
  ///   print("\(failure.zoneName): \(failure.serverErrorCode.rawValue)")
  /// }
  /// ```
  public func modifyZones(
    _ operations: [ZoneOperation],
    database: Database
  ) async throws(CloudKitError) -> [ZoneChangeResult] {
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

      return try (zonesData.zones ?? []).map { try ZoneChangeResult(from: $0) }
    } catch {
      throw mapToCloudKitError(error, context: "modifyZones")
    }
  }

  /// Create a single zone in the target database.
  ///
  /// Convenience wrapper over ``modifyZones(_:database:)`` for the common case
  /// of creating one zone. CloudKit's `zones/modify` endpoint is only supported
  /// on `.private` and `.shared`.
  ///
  /// - Parameters:
  ///   - zoneName: Non-empty zone name. Case-sensitive.
  ///   - ownerRecordName: Optional owner record name. Pass `nil` for the
  ///     caller's own zones (typical).
  ///   - database: Target database. Must not be `.public`.
  /// - Returns: `ZoneInfo` for the created zone.
  /// - Throws: `CloudKitError`. ``CloudKitError/zoneOperationFailed(_:)`` when
  ///   CloudKit rejects the zone — carrying the zone name, `serverErrorCode`
  ///   and `reason` — or ``CloudKitError/invalidResponse`` if the server
  ///   returns no entry at all.
  ///
  /// # Example
  /// ```swift
  /// let zone = try await service.createZone(
  ///   zoneName: "Articles",
  ///   database: .private
  /// )
  /// ```
  public func createZone(
    zoneName: String,
    ownerRecordName: String? = nil,
    database: Database
  ) async throws(CloudKitError) -> ZoneInfo {
    let operation = ZoneOperation.create(
      ZoneID(zoneName: zoneName, ownerName: ownerRecordName)
    )

    let results = try await modifyZones([operation], database: database)
    guard let result = results.first else {
      throw CloudKitError.invalidResponse
    }
    return try result.get()
  }

  /// Delete a single zone from the target database.
  ///
  /// Convenience wrapper over ``modifyZones(_:database:)`` for the common case
  /// of deleting one zone. CloudKit's `zones/modify` endpoint is only supported
  /// on `.private` and `.shared`.
  ///
  /// - Parameters:
  ///   - zoneName: Non-empty zone name. Case-sensitive.
  ///   - ownerRecordName: Optional owner record name. Pass `nil` for the
  ///     caller's own zones (typical).
  ///   - database: Target database. Must not be `.public`.
  /// - Throws: `CloudKitError` if validation fails or the request fails, or
  ///   ``CloudKitError/zoneOperationFailed(_:)`` when CloudKit rejects the
  ///   delete — for example `ZONE_NOT_FOUND`.
  ///
  /// # Example
  /// ```swift
  /// try await service.deleteZone(
  ///   zoneName: "Articles",
  ///   database: .private
  /// )
  /// ```
  public func deleteZone(
    zoneName: String,
    ownerRecordName: String? = nil,
    database: Database
  ) async throws(CloudKitError) {
    let operation = ZoneOperation.delete(
      ZoneID(zoneName: zoneName, ownerName: ownerRecordName)
    )

    let results = try await modifyZones([operation], database: database)
    for result in results {
      _ = try result.get()
    }
  }
}

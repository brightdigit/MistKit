//
//  CloudKitService+AssetRereference.swift
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

internal import MistKitOpenAPI

extension CloudKitService {
  /// Fetch reusable asset descriptors for assets that already live on other
  /// records, without re-uploading the bytes (`assets/rereference`).
  ///
  /// Each returned ``Asset`` descriptor can then be set on another record's
  /// Asset field via `modifyRecords`/`updateRecord` to share the same
  /// underlying asset. The asset's bytes are only deleted once all references
  /// to it are removed.
  ///
  /// - Parameters:
  ///   - fields: The source `(recordName, fieldName)` pairs to re-reference.
  ///   - zoneID: Optional zone ID; defaults to the default zone when `nil`.
  ///   - database: The CloudKit database scope (`.public`, `.private`, `.shared`).
  /// - Returns: One reusable ``Asset`` descriptor per requested field, in order.
  /// - Throws: ``CloudKitError``. The endpoint validates atomically — a bad
  ///   entry (e.g. a missing source record) fails the *whole* request with a
  ///   top-level ``CloudKitError/badRequest(reason:)``, so there are no
  ///   per-item failures to inspect.
  public func rereferenceAssets(
    _ fields: [(recordName: RecordName, fieldName: String)],
    zoneID: ZoneID? = nil,
    database: Database
  ) async throws(CloudKitError) -> [Asset] {
    do {
      let assetRequests = fields.map { field in
        Operations.rereferenceAssets.Input.Body.jsonPayload.assetsPayloadPayload(
          recordName: field.recordName.rawValue,
          fieldName: field.fieldName
        )
      }

      let requestBody = Operations.rereferenceAssets.Input.Body.jsonPayload(
        zoneID: zoneID.map { Components.Schemas.ZoneID(from: $0) },
        assets: assetRequests
      )

      let client = try self.client(for: database)
      let response = try await client.rereferenceAssets(
        path: Operations.rereferenceAssets.Input.Path(
          containerIdentifier: containerIdentifier,
          environment: environment,
          database: database
        ),
        body: .json(requestBody)
      )

      let rereferenceData: Components.Schemas.AssetRereferenceResponse =
        try await responseProcessor.processRereferenceAssetsResponse(response)

      return (rereferenceData.assets ?? []).map { Asset(from: $0) }
    } catch {
      throw mapToCloudKitError(error, context: "rereferenceAssets")
    }
  }

  /// Re-reference an asset from one record onto another in a single call.
  ///
  /// Composes `assets/rereference` with `records/modify`: fetches the reusable
  /// descriptor for the source field, then writes it onto the target record's
  /// asset field — sharing the same underlying asset bytes without re-uploading.
  /// Mirrors the native `CloudKitStore.rereferenceAsset` convenience.
  ///
  /// The target record's `recordType` and current change tag are discovered via
  /// a `lookupRecords` call, so callers need only name the target record. Callers
  /// that already hold the target's `recordType` and `recordChangeTag` can skip
  /// that round trip with the overload below.
  ///
  /// - Parameters:
  ///   - sourceRecordName: The record holding the source asset.
  ///   - assetField: The Asset field on the source record.
  ///   - targetRecordName: The record that should reference the same asset.
  ///   - targetField: The Asset field on the target record. Defaults to
  ///     `assetField` when `nil`.
  ///   - zoneID: Optional zone ID; defaults to the default zone when `nil`.
  ///   - database: The CloudKit database scope (`.public`, `.private`, `.shared`).
  /// - Returns: The updated target ``RecordInfo``.
  /// - Throws: ``CloudKitError`` — a top-level failure (e.g.
  ///   ``CloudKitError/badRequest(reason:)``) if the source asset could not be
  ///   re-referenced; ``CloudKitError/incompleteResponse(reason:)`` if the target
  ///   record is not found or carries no `recordType`; or a record failure if the
  ///   target lookup or update failed.
  public func rereferenceAsset(
    fromRecord sourceRecordName: RecordName,
    field assetField: String,
    toRecord targetRecordName: RecordName,
    field targetField: String? = nil,
    zoneID: ZoneID? = nil,
    database: Database
  ) async throws(CloudKitError) -> RecordInfo {
    let lookups = try await lookupRecords(
      recordNames: [targetRecordName],
      database: database
    )
    guard let firstLookup = lookups.first else {
      throw CloudKitError.incompleteResponse(
        reason: "target record '\(targetRecordName)' was not found"
      )
    }
    let targetInfo = try firstLookup.get()
    guard let recordType = targetInfo.recordType else {
      throw CloudKitError.incompleteResponse(
        reason: "target record '\(targetRecordName)' returned no recordType"
      )
    }

    return try await rereferenceAsset(
      fromRecord: sourceRecordName,
      field: assetField,
      toRecord: targetRecordName,
      recordType: recordType,
      recordChangeTag: targetInfo.recordChangeTag,
      field: targetField,
      zoneID: zoneID,
      database: database
    )
  }

  /// Re-reference an asset onto a target whose `recordType` and change tag are
  /// already known, skipping the `lookupRecords` round trip the other overload
  /// performs.
  ///
  /// - Parameters:
  ///   - sourceRecordName: The record holding the source asset.
  ///   - assetField: The Asset field on the source record.
  ///   - targetRecordName: The record that should reference the same asset.
  ///   - recordType: The target record's type.
  ///   - recordChangeTag: The target record's current change tag, or `nil` to
  ///     write without optimistic-concurrency checking.
  ///   - targetField: The Asset field on the target record. Defaults to
  ///     `assetField` when `nil`.
  ///   - zoneID: Optional zone ID; defaults to the default zone when `nil`.
  ///   - database: The CloudKit database scope (`.public`, `.private`, `.shared`).
  /// - Returns: The updated target ``RecordInfo``.
  /// - Throws: ``CloudKitError`` — a top-level failure (e.g.
  ///   ``CloudKitError/badRequest(reason:)``) if the source asset could not be
  ///   re-referenced; ``CloudKitError/incompleteResponse(reason:)`` if
  ///   `assets/rereference` returned no descriptor for the source field; or a
  ///   record failure if the target update failed.
  public func rereferenceAsset(
    fromRecord sourceRecordName: RecordName,
    field assetField: String,
    toRecord targetRecordName: RecordName,
    recordType: String,
    recordChangeTag: String?,
    field targetField: String? = nil,
    zoneID: ZoneID? = nil,
    database: Database
  ) async throws(CloudKitError) -> RecordInfo {
    let resolvedTargetField = targetField ?? assetField

    let descriptors = try await rereferenceAssets(
      [(recordName: sourceRecordName, fieldName: assetField)],
      zoneID: zoneID,
      database: database
    )
    guard let asset = descriptors.first else {
      throw CloudKitError.incompleteResponse(
        reason: "assets/rereference returned no descriptor for record "
          + "'\(sourceRecordName)' field '\(assetField)'"
      )
    }

    return try await updateRecord(
      recordType: recordType,
      recordName: targetRecordName,
      fields: [resolvedTargetField: .asset(asset)],
      recordChangeTag: recordChangeTag,
      database: database
    )
  }
}

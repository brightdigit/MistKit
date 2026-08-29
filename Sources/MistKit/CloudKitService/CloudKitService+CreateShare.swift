//
//  CloudKitService+CreateShare.swift
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

extension CloudKitService {
  /// Create a CloudKit share for a new root record (`records/modify`).
  ///
  /// Performs two modify requests against `database` in `zoneID`, matching
  /// Apple's Sharing Records sequence:
  /// 1. Creates the root record with `createShortGUID: true` (stable URL).
  /// 2. Creates a ``ShareInfo/recordType`` (`cloudkit.share`) with
  ///    `forRecord` (name + change tag), `atomic: true`, public permission,
  ///    and participants.
  ///
  /// Returns the generated short GUID and the standard iCloud share URL
  /// (`https://www.icloud.com/share/{shortGUID}`). Share metadata is carried
  /// on ``CreatedShare`` / ``ShareInfo`` — not on ``RecordInfo``.
  ///
  /// Custom zones are required for sharing; Apple's reference uses a private
  /// custom zone. The service credentials must be able to write that database
  /// (typically private + web-auth).
  ///
  /// - Parameters:
  ///   - rootRecordType: The record type for the shared root record.
  ///   - rootRecordName: Optional root record name; CloudKit generates one when
  ///     omitted.
  ///   - rootFields: Fields for the root record.
  ///   - zoneID: The custom zone that will hold the root and share records.
  ///   - publicPermission: Public access on the share (default `.none`).
  ///   - participants: Participants to invite (typically a sharee identified by
  ///     email lookup info, with `.invited` acceptance status).
  ///   - database: Database scope for the create (usually `.private`).
  /// - Returns: The created share, including short GUID and invite URL.
  /// - Throws: ``CloudKitError``.
  public func createShare(
    rootRecordType: String,
    rootRecordName: String? = nil,
    rootFields: [String: FieldValue] = [:],
    zoneID: ZoneID,
    publicPermission: SharePermission = .none,
    participants: [ShareParticipant],
    database: Database
  ) async throws(CloudKitError) -> CreatedShare {
    do {
      // Pre-assign the root name so the share step can target it even if the
      // caller omitted `rootRecordName`.
      let resolvedRootName =
        rootRecordName ?? "mistkit-share-root-\(UUID().uuidString.lowercased())"
      let (rootRecord, rootChangeTag) = try await createShareRoot(
        recordType: rootRecordType,
        recordName: resolvedRootName,
        fields: rootFields,
        zoneID: zoneID,
        database: database
      )
      // Share creates must be atomic; forRecord must include the root's
      // change tag. Wire type is `cloudkit.share` (lowercase k) — Apple's
      // archived docs say `cloudKit.share`, which the server rejects with
      // "Cannot share - no such record exists to share".
      return try await createShareRecord(
        rootRecord: rootRecord,
        rootChangeTag: rootChangeTag,
        zoneID: zoneID,
        publicPermission: publicPermission,
        participants: participants,
        database: database
      )
    } catch {
      throw mapToCloudKitError(error, context: "createShare")
    }
  }

  private func createShareRoot(
    recordType: String,
    recordName: String,
    fields: [String: FieldValue],
    zoneID: ZoneID,
    database: Database
  ) async throws -> (RecordInfo, String) {
    let rootSchemas = try await modifyRecordResponses(
      [
        RecordOperation(
          operationType: .create,
          recordType: recordType,
          recordName: recordName,
          fields: fields,
          createShortGUID: true
        )
      ],
      zoneID: zoneID,
      database: database,
      atomic: false
    )
    guard let rootSchema = rootSchemas.first else {
      throw CloudKitError.incompleteResponse(
        reason: "createShare root create returned no records"
      )
    }
    let rootRecord = try RecordInfo(from: rootSchema)
    guard let rootChangeTag = rootSchema.recordChangeTag else {
      throw CloudKitError.incompleteResponse(
        reason:
          "createShare root create omitted recordChangeTag "
          + "(required by forRecord when creating \(ShareInfo.recordType))"
      )
    }
    return (rootRecord, rootChangeTag)
  }

  private func createShareRecord(
    rootRecord: RecordInfo,
    rootChangeTag: String,
    zoneID: ZoneID,
    publicPermission: SharePermission,
    participants: [ShareParticipant],
    database: Database
  ) async throws -> CreatedShare {
    let shareSchemas = try await modifyRecordResponses(
      [
        RecordOperation(
          operationType: .create,
          recordType: ShareInfo.recordType,
          recordName: nil,
          fields: [:],
          forRecord: ShareTargetReference(
            recordName: rootRecord.recordName,
            recordChangeTag: rootChangeTag
          ),
          publicPermission: publicPermission,
          participants: participants
        )
      ],
      zoneID: zoneID,
      database: database,
      atomic: true
    )
    guard let shareSchema = shareSchemas.first else {
      throw CloudKitError.incompleteResponse(
        reason: "createShare share create returned no records"
      )
    }
    guard let share = ShareInfo(from: shareSchema) else {
      try ConversionError.shareIncomplete.reportAndThrow()
    }
    guard let shareRecordName = shareSchema.recordName else {
      try ConversionError.recordMissingRecordName.reportAndThrow()
    }
    return CreatedShare(
      shortGUID: share.shortGUID,
      shareURL: CreatedShare.shareURL(forShortGUID: share.shortGUID),
      share: share,
      rootRecord: rootRecord,
      shareRecordName: shareRecordName
    )
  }
}

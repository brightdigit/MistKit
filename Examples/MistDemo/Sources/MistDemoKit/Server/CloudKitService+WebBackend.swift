//
//  CloudKitService+WebBackend.swift
//  MistDemo
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
internal import MistKit

extension CloudKitService: WebBackend {
  internal func webQuery(
    recordType: String,
    limit: Int?,
    sortBy: [WebRequests.QuerySortField]?,
    zone: WebRequests.ZoneSelector?,
    database: MistKit.Database
  ) async throws -> [RecordInfo] {
    let querySorts = sortBy?.map { sort in
      QuerySort.sort(sort.field, ascending: sort.ascending)
    }
    let result = try await queryRecords(
      Query(recordType: recordType, sortBy: querySorts ?? []),
      limit: limit,
      desiredKeys: nil,
      continuationMarker: nil,
      zoneID: zone?.zoneID,
      database: database
    )
    return result.records
  }

  internal func webCreate(
    recordType: String,
    recordName: String?,
    fields: [String: FieldValue],
    database: MistKit.Database
  ) async throws -> RecordInfo {
    try await createRecord(
      recordType: recordType,
      recordName: recordName,
      fields: fields,
      database: database
    )
  }

  internal func webUpdate(
    recordType: String,
    recordName: String,
    fields: [String: FieldValue],
    recordChangeTag: String?,
    database: MistKit.Database
  ) async throws -> RecordInfo {
    try await updateRecord(
      recordType: recordType,
      recordName: recordName,
      fields: fields,
      recordChangeTag: recordChangeTag,
      database: database
    )
  }

  internal func webDelete(
    recordType: String,
    recordName: String,
    recordChangeTag: String?,
    database: MistKit.Database
  ) async throws {
    try await deleteRecord(
      recordType: recordType,
      recordName: recordName,
      recordChangeTag: recordChangeTag,
      database: database
    )
  }

  internal func webModifyZones(
    create: [String],
    delete: [String],
    database: MistKit.Database
  ) async throws -> [ZoneInfo] {
    let operations =
      create.map { ZoneOperation.create(ZoneID(zoneName: $0)) }
      + delete.map { ZoneOperation.delete(ZoneID(zoneName: $0)) }
    let results = try await modifyZones(operations, database: database)
    // All-or-nothing, matching `webLookupRecords`: `modifyZones` returns a
    // per-zone `[ZoneChangeResult]`, but the demo collapses it so any single
    // rejection (e.g. ZONE_NOT_FOUND on a delete) surfaces in the web panel
    // instead of silently returning fewer zones than were asked for.
    return try results.map { try $0.get() }
  }

  internal func webListSubscriptions(
    database: MistKit.Database
  ) async throws -> [SubscriptionInfo] {
    try await listSubscriptions(database: database)
  }

  internal func webLookupSubscriptions(
    ids: [String],
    database: MistKit.Database
  ) async throws -> [SubscriptionInfo] {
    try await lookupSubscriptions(ids: ids, database: database)
  }

  internal func webModifySubscriptions(
    operations: [SubscriptionOperation],
    database: MistKit.Database
  ) async throws -> [SubscriptionInfo] {
    let results = try await modifySubscriptions(operations, database: database)
    // Surface any per-subscription failure (e.g. CloudKit's INTERNAL_ERROR on
    // create) as a thrown error so the web panel shows it — matching what
    // CloudKit JS reports — rather than silently returning fewer rows.
    return try results.map { try $0.get() }
  }

  internal func webCreateToken(
    environment: APNsEnvironment,
    clientId: String?,
    database: MistKit.Database
  ) async throws -> APNsTokenResult {
    try await createAPNsToken(
      environment: environment,
      clientId: clientId,
      database: database
    )
  }

  internal func webRegisterToken(
    apnsToken: String,
    environment: APNsEnvironment,
    clientId: String?,
    database: MistKit.Database
  ) async throws {
    try await registerAPNsToken(
      apnsToken,
      environment: environment,
      clientId: clientId,
      database: database
    )
  }

  internal func webRereferenceAsset(
    sourceRecordName: String,
    assetField: String,
    targetRecordName: String,
    targetAssetField: String?,
    database: MistKit.Database
  ) async throws -> RecordInfo {
    try await rereferenceAsset(
      fromRecord: sourceRecordName,
      field: assetField,
      toRecord: targetRecordName,
      field: targetAssetField,
      database: database
    )
  }

  internal func webUploadAsset(
    data: Data,
    recordType: String,
    fieldName: String,
    recordName: String?,
    database: MistKit.Database
  ) async throws -> AssetUploadReceipt {
    try await uploadAssets(
      data: data,
      recordType: recordType,
      fieldName: fieldName,
      recordName: recordName,
      database: database
    )
  }
}

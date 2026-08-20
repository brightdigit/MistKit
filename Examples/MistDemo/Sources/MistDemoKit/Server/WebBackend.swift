//
//  WebBackend.swift
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

/// Narrow abstraction over the MistKit `CloudKitService` methods the web
/// demo's CRUD routes call. Lets the routes be tested without a live
/// CloudKit container — tests supply a mock conformer.
///
/// The production implementation is `CloudKitService` itself via
/// extension; the web demo builds a new service per request using the
/// captured `ckWebAuthToken` (and, when configured, server-to-server
/// signing material for the public database).
internal protocol WebBackend: Sendable {
  func webQuery(
    recordType: String,
    limit: Int?,
    sortBy: [WebRequests.QuerySortField]?,
    zoneName: String?,
    zoneOwner: String?,
    database: MistKit.Database
  ) async throws -> [RecordInfo]

  func webCreate(
    recordType: String,
    recordName: String?,
    fields: [String: FieldValue],
    database: MistKit.Database
  ) async throws -> RecordInfo

  func webUpdate(
    recordType: String,
    recordName: String,
    fields: [String: FieldValue],
    recordChangeTag: String?,
    database: MistKit.Database
  ) async throws -> RecordInfo

  func webDelete(
    recordType: String,
    recordName: String,
    recordChangeTag: String?,
    database: MistKit.Database
  ) async throws

  func webLookupRecords(
    recordNames: [String],
    database: MistKit.Database
  ) async throws -> [RecordInfo]

  func webRecordChanges(
    zoneName: String?,
    syncToken: String?,
    database: MistKit.Database
  ) async throws -> RecordChangesResult

  func webModifyZones(
    create: [String],
    delete: [String],
    database: MistKit.Database
  ) async throws -> [ZoneInfo]

  func webListZones(
    database: MistKit.Database
  ) async throws -> [ZoneInfo]

  func webLookupZones(
    zoneNames: [String],
    database: MistKit.Database
  ) async throws -> [ZoneInfo]

  func webZoneChanges(
    syncToken: String?,
    database: MistKit.Database
  ) async throws -> ZoneChangesResult

  func webFetchCaller() async throws -> UserInfo

  func webDiscoverUsers(
    emails: [String],
    phoneNumbers: [String],
    userRecordNames: [String]
  ) async throws -> [UserIdentity]

  func webListSubscriptions(
    database: MistKit.Database
  ) async throws -> [SubscriptionInfo]

  func webLookupSubscriptions(
    ids: [String],
    database: MistKit.Database
  ) async throws -> [SubscriptionInfo]

  func webModifySubscriptions(
    operations: [SubscriptionOperation],
    database: MistKit.Database
  ) async throws -> [SubscriptionInfo]

  func webCreateToken(
    environment: APNsEnvironment,
    clientId: String?,
    database: MistKit.Database
  ) async throws -> APNsTokenResult

  func webRegisterToken(
    apnsToken: String,
    environment: APNsEnvironment,
    clientId: String?,
    database: MistKit.Database
  ) async throws

  func webRereferenceAsset(
    sourceRecordName: String,
    assetField: String,
    targetRecordName: String,
    targetAssetField: String?,
    database: MistKit.Database
  ) async throws -> RecordInfo

  func webUploadAsset(
    data: Data,
    recordType: String,
    fieldName: String,
    recordName: String?,
    database: MistKit.Database
  ) async throws -> AssetUploadReceipt

  func webResolveShares(
    shortGUIDs: [String],
    fetchRootRecord: Bool?,
    fields: [String]?
  ) async throws -> [ShareRecordInfo]

  func webAcceptShares(
    shortGUIDs: [String],
    fetchRootRecord: Bool?,
    fields: [String]?
  ) async throws -> [ShareRecordInfo]
}

// The `CloudKitService: WebBackend` conformance lives in
// `CloudKitService+WebBackend.swift`.

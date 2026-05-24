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
    database: MistKit.Database
  ) async throws -> [RecordInfo]

  func webCreate(
    recordType: String,
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

  func webModifyZones(
    create: [String],
    delete: [String],
    database: MistKit.Database
  ) async throws -> [ZoneInfo]

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
    database: MistKit.Database
  ) async throws -> APNsTokenResult

  func webRegisterToken(
    apnsToken: String,
    database: MistKit.Database
  ) async throws
}

extension CloudKitService: WebBackend {
  internal func webQuery(
    recordType: String,
    limit: Int?,
    sortBy: [WebRequests.QuerySortField]?,
    database: MistKit.Database
  ) async throws -> [RecordInfo] {
    let querySorts = sortBy?.map { sort in
      QuerySort.sort(sort.field, ascending: sort.ascending)
    }
    let result = try await queryRecords(
      recordType: recordType,
      filters: nil,
      sortBy: querySorts,
      limit: limit,
      desiredKeys: nil,
      continuationMarker: nil,
      database: database
    )
    return result.records
  }

  internal func webCreate(
    recordType: String,
    fields: [String: FieldValue],
    database: MistKit.Database
  ) async throws -> RecordInfo {
    try await createRecord(
      recordType: recordType,
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
    return try await modifyZones(operations, database: database)
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
    try await modifySubscriptions(operations, database: database)
  }

  internal func webCreateToken(
    environment: APNsEnvironment,
    database: MistKit.Database
  ) async throws -> APNsTokenResult {
    try await createAPNsToken(environment: environment, database: database)
  }

  internal func webRegisterToken(
    apnsToken: String,
    database: MistKit.Database
  ) async throws {
    try await registerAPNsToken(apnsToken, database: database)
  }
}

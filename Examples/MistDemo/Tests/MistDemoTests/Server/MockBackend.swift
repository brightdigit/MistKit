//
//  MockBackend.swift
//  MistDemoTests
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

#if canImport(Hummingbird)
  internal import Foundation
  internal import MistKit

  @testable import MistDemoKit

  /// In-memory `WebBackend` for routing-level tests. Records the last
  /// call to each operation and returns deterministic stub records.
  internal final actor MockBackend: WebBackend {
    internal private(set) var lastQuery: QueryCall?
    internal private(set) var lastCreate: CreateCall?
    internal private(set) var lastUpdate: UpdateCall?
    internal private(set) var lastDelete: DeleteCall?
    internal private(set) var lastModifyZones: ModifyZonesCall?
    internal private(set) var didListSubscriptions = false
    internal private(set) var lastLookupSubscriptions: LookupSubscriptionsCall?
    internal private(set) var lastModifySubscriptions: ModifySubscriptionsCall?
    internal private(set) var lastCreateToken: CreateTokenCall?
    internal private(set) var lastRegisterToken: RegisterTokenCall?
    internal private(set) var lastRereferenceAsset: RereferenceAssetCall?
    internal private(set) var lastUploadAsset: UploadAssetCall?
    private var pendingError: String?

    /// Stub subscriptions (tests can seed); defaults to one query subscription.
    private var stubSubscriptions: [SubscriptionInfo] = [
      .query(subscriptionID: "stub-sub", recordType: "Note", firesOn: [.create])
    ]

    internal func failNext(message: String) {
      pendingError = message
    }

    internal func webQuery(
      recordType: String,
      limit: Int?,
      sortBy: [WebRequests.QuerySortField]?,
      database: MistKit.Database
    ) async throws -> [RecordInfo] {
      lastQuery = QueryCall(
        recordType: recordType,
        limit: limit,
        sortBy: sortBy,
        database: database
      )
      try consumePendingError()
      return [
        Self.stubRecord(recordType: recordType, recordName: "stub-1")
      ]
    }

    internal func webCreate(
      recordType: String,
      recordName: String?,
      fields: [String: FieldValue],
      database: MistKit.Database
    ) async throws -> RecordInfo {
      lastCreate = CreateCall(
        recordType: recordType,
        recordName: recordName,
        fields: Self.flatten(fields),
        database: database
      )
      try consumePendingError()
      return Self.stubRecord(
        recordType: recordType, recordName: recordName ?? "created-1"
      )
    }

    internal func webUpdate(
      recordType: String,
      recordName: String,
      fields: [String: FieldValue],
      recordChangeTag: String?,
      database: MistKit.Database
    ) async throws -> RecordInfo {
      lastUpdate = UpdateCall(
        recordType: recordType,
        recordName: recordName,
        fields: Self.flatten(fields),
        recordChangeTag: recordChangeTag,
        database: database
      )
      try consumePendingError()
      return Self.stubRecord(
        recordType: recordType, recordName: recordName
      )
    }

    internal func webDelete(
      recordType: String,
      recordName: String,
      recordChangeTag: String?,
      database: MistKit.Database
    ) async throws {
      lastDelete = DeleteCall(
        recordType: recordType,
        recordName: recordName,
        recordChangeTag: recordChangeTag,
        database: database
      )
      try consumePendingError()
    }

    internal func webModifyZones(
      create: [String],
      delete: [String],
      database: MistKit.Database
    ) async throws -> [ZoneInfo] {
      lastModifyZones = ModifyZonesCall(
        create: create,
        delete: delete,
        database: database
      )
      try consumePendingError()
      return create.map { name in
        ZoneInfo(zoneName: name, ownerRecordName: nil, capabilities: [])
      }
    }

    internal func webListSubscriptions(
      database: MistKit.Database
    ) async throws -> [SubscriptionInfo] {
      didListSubscriptions = true
      try consumePendingError()
      return stubSubscriptions
    }

    internal func webLookupSubscriptions(
      ids: [String],
      database: MistKit.Database
    ) async throws -> [SubscriptionInfo] {
      lastLookupSubscriptions = LookupSubscriptionsCall(ids: ids, database: database)
      try consumePendingError()
      return stubSubscriptions.filter { ids.contains($0.subscriptionID) }
    }

    internal func webModifySubscriptions(
      operations: [SubscriptionOperation],
      database: MistKit.Database
    ) async throws -> [SubscriptionInfo] {
      lastModifySubscriptions = ModifySubscriptionsCall(
        operations: operations, database: database
      )
      try consumePendingError()
      return operations.compactMap { operation in
        if case .create(let info) = operation {
          return info
        }
        return nil
      }
    }

    internal func webCreateToken(
      environment: APNsEnvironment,
      clientId: String?,
      database: MistKit.Database
    ) async throws -> APNsTokenResult {
      lastCreateToken = CreateTokenCall(
        environment: environment,
        clientId: clientId,
        database: database
      )
      try consumePendingError()
      guard let stubURL = URL(string: "https://stub.example/webcourier") else {
        struct InvalidStubURL: Error {}
        throw InvalidStubURL()
      }
      return APNsTokenResult(
        environment: environment,
        apnsToken: "stub-apns",
        webcourierURL: stubURL
      )
    }

    internal func webRegisterToken(
      apnsToken: String,
      environment: APNsEnvironment,
      clientId: String?,
      database: MistKit.Database
    ) async throws {
      lastRegisterToken = RegisterTokenCall(
        apnsToken: apnsToken,
        environment: environment,
        clientId: clientId,
        database: database
      )
      try consumePendingError()
    }

    internal func webRereferenceAsset(
      sourceRecordName: String,
      assetField: String,
      targetRecordName: String,
      targetAssetField: String?,
      database: MistKit.Database
    ) async throws -> RecordInfo {
      lastRereferenceAsset = RereferenceAssetCall(
        sourceRecordName: sourceRecordName,
        assetField: assetField,
        targetRecordName: targetRecordName,
        targetAssetField: targetAssetField,
        database: database
      )
      try consumePendingError()
      return Self.stubRecord(
        recordType: "Note", recordName: targetRecordName
      )
    }

    internal func webUploadAsset(
      data: Data,
      recordType: String,
      fieldName: String,
      recordName: String?,
      database: MistKit.Database
    ) async throws -> AssetUploadReceipt {
      lastUploadAsset = UploadAssetCall(
        data: data,
        recordType: recordType,
        fieldName: fieldName,
        recordName: recordName,
        database: database
      )
      try consumePendingError()
      let assignedName = recordName ?? "stub-upload-\(data.count)"
      return AssetUploadReceipt(
        asset: Asset(
          fileChecksum: "stub-checksum",
          size: Int64(data.count),
          referenceChecksum: nil,
          wrappingKey: nil,
          receipt: "stub-receipt",
          downloadURL: nil
        ),
        recordName: assignedName,
        fieldName: fieldName
      )
    }

    private func consumePendingError() throws {
      if let message = pendingError {
        pendingError = nil
        struct StubError: LocalizedError {
          let errorDescription: String?
        }
        throw StubError(errorDescription: message)
      }
    }
  }
#endif

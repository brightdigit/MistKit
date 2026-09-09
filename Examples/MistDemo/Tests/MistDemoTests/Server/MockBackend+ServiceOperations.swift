//
//  MockBackend+ServiceOperations.swift
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

  extension MockBackend {
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
      zone: WebRequests.ZoneSelector?,
      database: MistKit.Database
    ) async throws -> AssetUploadReceipt {
      lastUploadAsset = UploadAssetCall(
        data: data,
        recordType: recordType,
        fieldName: fieldName,
        recordName: recordName,
        zone: zone,
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
  }
#endif

//
//  ConversionFailureTests.swift
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
internal import Testing

@testable import MistKit

/// Verifies that response→domain conversions fail loudly (throwing
/// `CloudKitError`) instead of silently dropping or masking data. The DEBUG
/// assertion trap is suppressed so the thrown error is observable.
@Suite("Conversion Failures")
internal struct ConversionFailureTests {
  /// Runs `body`, expecting it to throw a `ConversionError`, with the DEBUG
  /// assertion handler suppressed so the throw is observed rather than trapped.
  private func expectConversionThrow(
    _ body: () throws -> Void
  ) {
    ConversionFailureReporter.$assertionHandler.withValue(
      { _, _, _ in },
      operation: {
        #expect(throws: ConversionError.self) {
          try body()
        }
      }
    )
  }

  @Test("FieldValue throws on a reference field missing recordName")
  internal func referenceMissingRecordNameThrows() {
    let response = Components.Schemas.FieldValueResponse(
      value: .ReferenceValue(.init(recordName: nil))
    )
    expectConversionThrow {
      _ = try FieldValue(response, fieldName: "owner")
    }
  }

  @Test("RecordInfo throws on a field that cannot be mapped")
  internal func recordInfoThrowsOnReferenceWithoutRecordName() {
    let record = Components.Schemas.RecordResponse(
      recordName: "rec-1",
      recordType: "Article",
      fields: .init(additionalProperties: [
        "owner": .init(value: .ReferenceValue(.init(recordName: nil)))
      ])
    )
    expectConversionThrow {
      _ = try RecordInfo(from: record)
    }
  }

  @Test("UserIdentity faithfully converts a non-discoverable user (nil userRecordName)")
  internal func userIdentityWithoutRecordNameIsFaithful() {
    // A non-discoverable user comes back with only lookupInfo; userRecordName
    // is legitimately nil and must not be treated as a conversion failure.
    let schema = Components.Schemas.UserIdentity()
    let identity = UserIdentity(from: schema)

    #expect(identity.userRecordName == .nonDiscoverable)
  }

  @Test("UserInfo throws when userRecordName is missing")
  internal func userInfoMissingRecordNameThrows() {
    let schema = Components.Schemas.UserResponse()
    expectConversionThrow {
      _ = try UserInfo(from: schema)
    }
  }

  @Test("RecordTimestamp throws on a negative timestamp")
  internal func recordTimestampNegativeThrows() {
    let schema = Components.Schemas.RecordTimestamp(timestamp: -1)
    expectConversionThrow {
      _ = try RecordTimestamp(from: schema)
    }
  }

  @Test("RecordResult maps an error item to .failure with the server error code")
  internal func recordResultMapsErrorItem() throws {
    let item = Components.Schemas.ModifyResponse.recordsPayloadPayload.RecordOperationFailure(
      .init(recordName: "rec-1", serverErrorCode: .NOT_FOUND)
    )
    let result = try RecordResult(from: item)

    guard case .failure(let error) = result else {
      Issue.record("Expected .failure, got \(result)")
      return
    }
    #expect(error.recordName == "rec-1")
    #expect(error.serverErrorCode == .notFound)
  }

  @Test("RecordResult maps a record item to .success")
  internal func recordResultMapsRecordItem() throws {
    let item = Components.Schemas.ModifyResponse.recordsPayloadPayload.RecordResponse(
      .init(recordName: "rec-1", recordType: "Article")
    )
    let result = try RecordResult(from: item)

    guard case .success(let record) = result else {
      Issue.record("Expected .success, got \(result)")
      return
    }
    #expect(record.recordName == "rec-1")
  }

  @Test("RecordResult.get() rethrows a failure as recordOperationFailed")
  internal func recordResultGetThrowsOnFailure() {
    let result = RecordResult.failure(
      RecordOperationFailure(recordName: "rec-1", serverErrorCode: .badRequest)
    )
    #expect(throws: CloudKitError.self) {
      _ = try result.get()
    }
  }

  @Test("BatchSyncResult partitions a mixed success/failure batch by classification")
  internal func batchSyncResultPartitionsMixedResults() throws {
    func successResult(_ recordName: String) throws -> RecordResult {
      try RecordResult(
        from: Components.Schemas.ModifyResponse.recordsPayloadPayload.RecordResponse(
          .init(recordName: recordName, recordType: "Article")
        )
      )
    }
    let createdRecord = try successResult("new-1")
    let updatedRecord = try successResult("existing-1")
    let anonymousRecord = try successResult("server-assigned")
    let failure = RecordResult.failure(
      RecordOperationFailure(recordName: "bad-1", serverErrorCode: .notFound)
    )

    let classification = OperationClassification(
      creates: ["new-1"],
      updates: ["existing-1"]
    )
    let batch = BatchSyncResult(
      results: [createdRecord, updatedRecord, anonymousRecord, failure],
      classification: classification
    )

    #expect(batch.created.map(\.recordName) == ["new-1"])
    #expect(batch.updated.map(\.recordName) == ["existing-1"])
    #expect(batch.unclassified.map(\.recordName) == ["server-assigned"])
    #expect(batch.failed.map(\.recordName) == ["bad-1"])
    // Every input result lands in exactly one bucket.
    #expect(batch.totalCount == 4)
    #expect(batch.succeededCount == 3)
    #expect(batch.failedCount == 1)
  }

  @Test("mapToCloudKitError promotes a thrown ConversionError to .conversionFailed")
  internal func mapToCloudKitErrorPromotesConversionError() throws {
    let service = try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(
        apiAuth: APICredentials(
          apiToken: TestConstants.apiToken,
          webAuthToken: TestConstants.webAuthToken
        )
      ),
      transport: MockTransport()
    )

    let mapped = service.mapToCloudKitError(
      ConversionError.zoneMissingName,
      context: "test"
    )

    guard case .conversionFailed(let conversionError) = mapped else {
      Issue.record("Expected .conversionFailed, got \(mapped)")
      return
    }
    #expect(conversionError == .zoneMissingName)
  }
}

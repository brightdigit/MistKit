//
//  CloudKitService+CreateShare+ModifyRecords.swift
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
  /// Run `records/modify` and return raw ``Components.Schemas.RecordResponse``
  /// values in request order, preserving share keys that ``RecordInfo`` drops.
  ///
  /// - Parameters:
  ///   - operations: Record operations to send.
  ///   - zoneID: Zone that holds the records.
  ///   - database: Database scope for the modify.
  ///   - atomic: Required `true` when any operation creates a
  ///     `cloudkit.share` ("You can only create a share with atomic=true").
  /// - Returns: Record responses in request order.
  /// - Throws: ``CloudKitError`` when the modify fails or a per-item
  ///   failure is returned.
  internal func modifyRecordResponses(
    _ operations: [RecordOperation],
    zoneID: ZoneID,
    database: Database,
    atomic: Bool
  ) async throws -> [Components.Schemas.RecordResponse] {
    let apiOperations = try operations.map {
      try Components.Schemas.RecordOperation(from: $0)
    }
    let client = try self.client(for: database)
    let response = try await client.modifyRecords(
      .init(
        path: .init(
          version: "1",
          container: containerIdentifier,
          environment: .init(from: environment),
          database: .init(from: database)
        ),
        body: .json(
          .init(
            operations: apiOperations,
            atomic: atomic,
            zoneID: Components.Schemas.ZoneID(from: zoneID),
            desiredKeys: nil,
            numbersAsStrings: nil
          )
        )
      )
    )

    let modifyResponse: Components.Schemas.ModifyResponse =
      try await responseProcessor.processModifyRecordsResponse(response)
    let items = modifyResponse.records ?? []
    var results: [Components.Schemas.RecordResponse] = []
    results.reserveCapacity(items.count)
    for item in items {
      switch item {
      case .RecordOperationFailure(let failure):
        throw CloudKitError.recordOperationFailed(OperationFailure(from: failure))
      case .RecordResponse(let record):
        if record.recordName == nil, record.recordType == nil {
          // CloudKit sometimes returns a per-item failure without `recordName`
          // (OpenAPI requires it on RecordOperationFailure), which then
          // decodes as an empty RecordResponse. Surface it as incomplete.
          throw CloudKitError.incompleteResponse(
            reason:
              "createShare modify returned an empty record entry "
              + "(likely a per-item failure without recordName)"
          )
        }
        results.append(record)
      }
    }
    return results
  }
}

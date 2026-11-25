//
//  CloudKitServiceTests.BatchChunking.ModifyAllRecords+Helpers.swift
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
internal import Testing

@testable import MistKit

extension CloudKitServiceTests.BatchChunking.ModifyAllRecords {
  /// What `.modifyIncomplete` carried.
  internal struct Incomplete {
    internal let completed: [RecordResult]
    internal let unsent: [ZonedRecordOperation]
    internal let underlying: CloudKitError
  }

  internal static let operationID = "modifyRecords"
  internal static let teams = ZoneID(zoneName: "Teams")

  internal static func operations(_ names: [String], in zoneID: ZoneID? = nil)
    -> [ZonedRecordOperation]
  {
    names.map { ZonedRecordOperation(.delete(recordType: "Note", recordName: $0), in: zoneID) }
  }

  internal static func names(_ prefix: String, _ count: Int) -> [String] {
    (0..<count).map { "\(prefix)\($0)" }
  }

  /// A `records/modify` success echoing `names` as deleted records.
  internal static func modified(_ names: [String]) throws -> ResponseConfig {
    let records = names.map { name -> [String: Any] in
      ["recordName": name, "recordType": "Note", "deleted": true]
    }
    return .success(body: try JSONSerialization.data(withJSONObject: ["records": records]))
  }

  internal static func throttled() -> ResponseConfig {
    .cloudKitError(statusCode: 429, serverErrorCode: "THROTTLED", reason: "slow down")
  }

  /// A provider answering each request in `responses` order.
  internal static func provider(_ responses: [ResponseConfig]) async -> ResponseProvider {
    let provider = ResponseProvider(defaultResponse: throttled())
    for response in responses {
      await provider.enqueue(response, for: operationID)
    }
    return provider
  }

  internal static func recordNames(_ results: [RecordResult]) -> [String] {
    results.compactMap { result in
      if case .success(let record) = result {
        return record.recordName
      }
      return nil
    }
  }

  internal static func recordNames(_ operations: [ZonedRecordOperation]) -> [String?] {
    operations.map(\.operation.recordName)
  }

  /// Runs `modifyAllRecords` expecting `.modifyIncomplete`.
  internal static func incomplete(
    _ operations: [ZonedRecordOperation],
    service: CloudKitService,
    atomicZones: Set<ZoneID> = [],
    batchSize: Int = 2
  ) async throws -> Incomplete {
    do {
      let results = try await service.modifyAllRecords(
        operations,
        atomicZones: atomicZones,
        database: .private,
        batchSize: batchSize
      )
      Issue.record("expected .modifyIncomplete, got \(results.count) results")
    } catch {
      if case .modifyIncomplete(let completed, let unsent, let underlying) = error {
        return Incomplete(completed: completed, unsent: unsent, underlying: underlying)
      }
      Issue.record("expected .modifyIncomplete, got \(error)")
    }
    throw CancellationError()
  }
}

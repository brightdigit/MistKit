//
//  CloudKitService+ModifyAllRecords.swift
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

/// A record operation and the zone its record is in.
///
/// `records/modify` takes one zone per request, so a batch spanning zones is
/// split by ``CloudKitService/modifyAllRecords(_:atomicZones:database:batchSize:)``.
public struct ZonedRecordOperation: Sendable {
  /// The record's zone; `nil` for the default zone.
  public let zoneID: ZoneID?
  /// The operation.
  public let operation: RecordOperation

  /// Creates a zoned operation.
  public init(_ operation: RecordOperation, in zoneID: ZoneID? = nil) {
    self.zoneID = zoneID
    self.operation = operation
  }
}

extension CloudKitService {
  /// Modify records across zones, any number at a time.
  ///
  /// Groups `operations` by zone (zones in the order they first appear,
  /// operations in input order within a zone), splits each zone's operations
  /// into requests of at most `batchSize`, and sends each request with
  /// `atomic: true` when its zone is in `atomicZones`.
  ///
  /// Atomicity holds per request, not across requests: a zone with more than
  /// `batchSize` operations commits in several all-or-nothing steps.
  ///
  /// - Parameters:
  ///   - operations: The operations and their zones (any length).
  ///   - atomicZones: Zones whose requests are atomic. Only custom zones in a
  ///     private database support atomic commits; the default zone ignores it.
  ///   - database: The database to modify.
  ///   - batchSize: Operations per request, clamped to
  ///     `1...maxRecordsPerRequest`.
  /// - Returns: A ``RecordResult`` per operation, grouped by zone in the order
  ///   above.
  /// - Throws: ``CloudKitError`` from the first request that fails; later
  ///   requests aren't sent.
  public func modifyAllRecords(
    _ operations: [ZonedRecordOperation],
    atomicZones: Set<ZoneID> = [],
    database: Database,
    batchSize: Int = CloudKitService.maxRecordsPerRequest
  ) async throws(CloudKitError) -> [RecordResult] {
    var zoneOrder: [ZoneID] = []
    var byZone: [ZoneID: [RecordOperation]] = [:]
    for zoned in operations {
      let zoneID = zoned.zoneID ?? .defaultZone
      if byZone[zoneID] == nil {
        zoneOrder.append(zoneID)
      }
      byZone[zoneID, default: []].append(zoned.operation)
    }
    var results: [RecordResult] = []
    for zoneID in zoneOrder {
      let atomic = atomicZones.contains(zoneID)
      results += try await chunkedBatches(
        byZone[zoneID] ?? [],
        batchSize: batchSize,
        context: "modifyAllRecords"
      ) { batch throws(CloudKitError) in
        try await self.modifyRecords(
          batch,
          atomic: atomic,
          zoneID: zoneID.isDefaultZone ? nil : zoneID,
          database: database
        )
      }
    }
    return results
  }
}

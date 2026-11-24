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
internal import MistKitOpenAPI

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
  /// One planned `records/modify` request.
  private struct ModifyRequest {
    let zoneID: ZoneID
    let atomic: Bool
    let operations: [ZonedRecordOperation]
  }

  /// The field error that encoding a request's operations would throw, if any:
  /// a `NaN` or infinite number. Operations that can't be converted at all are
  /// left for ``modifyRecords(_:atomic:zoneID:desiredKeys:numbersAsStrings:database:)``
  /// to report.
  private static func encodingFailure(
    in operations: [ZonedRecordOperation]
  ) -> CloudKitError? {
    guard
      let apiOperations = try? operations.map({
        try Components.Schemas.RecordOperation(from: $0.operation)
      })
    else {
      return nil
    }
    do {
      _ = try JSONEncoder.shared.encode(apiOperations)
      return nil
    } catch {
      return CloudKitError(
        encodingError: error,
        recordNames: operations.map(\.operation.recordName)
      )
    }
  }

  /// Groups `operations` by zone and splits each zone into requests.
  private static func modifyRequests(
    for operations: [ZonedRecordOperation],
    atomicZones: Set<ZoneID>,
    batchSize: Int
  ) -> [ModifyRequest] {
    var zoneOrder: [ZoneID] = []
    var byZone: [ZoneID: [ZonedRecordOperation]] = [:]
    let atomicZones = Set(atomicZones.map(\.normalized))
    for zoned in operations {
      let zoneID = (zoned.zoneID ?? .defaultZone).normalized
      if byZone[zoneID] == nil {
        zoneOrder.append(zoneID)
      }
      byZone[zoneID, default: []].append(zoned)
    }
    let size = min(max(batchSize, 1), CloudKitService.maxRecordsPerRequest)
    return zoneOrder.flatMap { zoneID -> [ModifyRequest] in
      let zoneOperations = byZone[zoneID] ?? []
      let atomic = atomicZones.contains(zoneID)
      return stride(from: 0, to: zoneOperations.count, by: size).map { start in
        ModifyRequest(
          zoneID: zoneID,
          atomic: atomic,
          operations: Array(zoneOperations[start..<min(start + size, zoneOperations.count)])
        )
      }
    }
  }

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
  /// ## When a request fails
  ///
  /// Requests are sent one at a time in the order above. When one throws,
  /// no later request is sent and the method throws
  /// ``CloudKitError/modifyIncomplete(completed:unsent:underlying:)``:
  ///
  /// - `completed`: the ``RecordResult``s of every request that came back,
  ///   in send order. These include per-record failures, which don't throw.
  /// - `unsent`: the failed request's operations followed by those of every
  ///   request after it, in send order, as passed in.
  /// - `underlying`: the error the failed request threw.
  ///
  /// This is the shape whichever request fails. When the first one fails,
  /// `completed` is empty and `unsent` holds every operation. Cancellation
  /// is checked before each request, as before; a cancelled task sends no
  /// further request and throws the same shape, with the cancellation error
  /// as `underlying`.
  ///
  /// - Important: The failed request's operations are reported as unsent,
  ///   but CloudKit may have applied some or all of them — for example when
  ///   the connection drops after the request was sent. A caller that sends
  ///   them again should expect a `CONFLICT` (or `EXISTS` for a create) for a
  ///   record that was in fact saved, and re-fetch it to find out.
  ///
  /// Every request is encoded before the first is sent. When one can't be (a
  /// field holding a `NaN` or infinite number), nothing is sent: `completed`
  /// is empty, `unsent` holds every operation, and `underlying` is
  /// ``CloudKitError/invalidFieldValue(recordName:fieldName:underlying:)``
  /// naming the record and field. ``CloudKitError/recordName`` and
  /// ``CloudKitError/fieldName`` read through to it.
  ///
  /// - Parameters:
  ///   - operations: The operations and their zones (any length).
  ///   - atomicZones: Zones whose requests are atomic. Only custom zones in a
  ///     private database support atomic commits; the default zone ignores it.
  ///     Zones are matched by ``ZoneID/normalized``, so a zone CloudKit
  ///     reported (with its type) matches one built from its name and owner.
  ///   - database: The database to modify.
  ///   - batchSize: Operations per request, clamped to
  ///     `1...maxRecordsPerRequest`.
  /// - Returns: A ``RecordResult`` per operation, grouped by zone in the order
  ///   above.
  /// - Throws: ``CloudKitError/modifyIncomplete(completed:unsent:underlying:)``
  ///   when any request fails or the task is cancelled; later requests
  ///   aren't sent.
  public func modifyAllRecords(
    _ operations: [ZonedRecordOperation],
    atomicZones: Set<ZoneID> = [],
    database: Database,
    batchSize: Int = CloudKitService.maxRecordsPerRequest
  ) async throws(CloudKitError) -> [RecordResult] {
    let requests = Self.modifyRequests(
      for: operations,
      atomicZones: atomicZones,
      batchSize: batchSize
    )
    // Encode every request before sending the first, so a field CloudKit can't
    // take stops the whole call with nothing saved.
    for request in requests {
      if let fieldError = Self.encodingFailure(in: request.operations) {
        throw .modifyIncomplete(completed: [], unsent: operations, underlying: fieldError)
      }
    }
    var results: [RecordResult] = []
    for (index, request) in requests.enumerated() {
      do throws(CloudKitError) {
        do {
          try Task.checkCancellation()
        } catch {
          throw mapToCloudKitError(error, context: "modifyAllRecords")
        }
        results += try await modifyRecords(
          request.operations.map(\.operation),
          atomic: request.atomic,
          zoneID: request.zoneID.requestZone,
          database: database
        )
      } catch {
        throw .modifyIncomplete(
          completed: results,
          unsent: requests[index...].flatMap(\.operations),
          underlying: error
        )
      }
    }
    return results
  }
}

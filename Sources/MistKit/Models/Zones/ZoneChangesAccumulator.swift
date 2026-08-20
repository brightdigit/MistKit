//
//  ZoneChangesAccumulator.swift
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

/// Merges the per-round results of ``CloudKitService/fetchAllRecordZoneChanges``
/// back into one entry per originally-requested zone.
///
/// `changes/zone` paginates per zone, so a single logical fetch can span
/// several rounds in which different subsets of zones are still reporting
/// `moreComing`. This accumulator keeps each zone's accumulated records and
/// latest sync token keyed by zone name, and computes the next round's pending
/// requests.
internal struct ZoneChangesAccumulator {
  /// A zone's state across rounds.
  private struct Entry {
    var zone: ZoneInfo?
    var records: [RecordInfo] = []
    var syncToken: String?
    var failure: ZoneOperationFailure?
  }

  /// Zone names in the order originally requested, so output order is stable.
  private let order: [String]
  private var entries: [String: Entry]

  /// Every record collected so far, across all zones.
  internal var allRecords: [RecordInfo] {
    order.flatMap { entries[$0]?.records ?? [] }
  }

  internal init(requested: [ZoneChangesRequest]) {
    var order: [String] = []
    var entries: [String: Entry] = [:]
    for request in requested {
      let name = request.zoneID.zoneName
      if entries[name] == nil {
        order.append(name)
        entries[name] = Entry(syncToken: request.syncToken)
      }
    }
    self.order = order
    self.entries = entries
  }

  /// Folds one round's result in and returns the requests for the next round.
  ///
  /// A zone continues only when it reports `moreComing` *and* made progress —
  /// a zone returning no records with an unchanged sync token is treated as
  /// stuck and dropped rather than re-requested forever.
  internal mutating func merge(
    _ result: RecordZoneChangesResult,
    pending: [ZoneChangesRequest],
    reverse: Bool?,
    desiredKeys: [String]?,
    resultsLimit: Int?,
    desiredRecordTypes: [String]?
  ) -> [ZoneChangesRequest] {
    let pendingByName = Dictionary(
      pending.map { ($0.zoneID.zoneName, $0) },
      uniquingKeysWith: { first, _ in first }
    )
    var next: [ZoneChangesRequest] = []

    for zoneResult in result.zones {
      switch zoneResult {
      case .failure(let failure):
        record(failure: failure)
      case .success(let changes):
        let name = changes.zone.zoneName
        let previousToken = entries[name]?.syncToken
        record(changes: changes)

        let madeProgress = !changes.records.isEmpty || changes.syncToken != previousToken
        guard changes.moreComing, madeProgress,
          let request = pendingByName[name]
        else {
          continue
        }
        next.append(
          ZoneChangesRequest(
            zoneID: request.zoneID,
            syncToken: changes.syncToken,
            reverse: request.reverse ?? reverse,
            desiredKeys: request.desiredKeys ?? desiredKeys,
            resultsLimit: request.resultsLimit ?? resultsLimit,
            desiredRecordTypes: request.desiredRecordTypes ?? desiredRecordTypes
          )
        )
      }
    }

    return next
  }

  /// Produces the merged result, preserving the originally-requested order.
  ///
  /// Zones the server never reported on are omitted rather than fabricated.
  internal func finish() -> RecordZoneChangesResult {
    let zones: [ZoneRecordChangesResult] = order.compactMap { name in
      guard let entry = entries[name] else {
        return nil
      }
      if let failure = entry.failure {
        return .failure(failure)
      }
      guard let zone = entry.zone else {
        return nil
      }
      return .success(
        ZoneRecordChanges(
          zone: zone,
          records: entry.records,
          syncToken: entry.syncToken,
          moreComing: false
        )
      )
    }
    return RecordZoneChangesResult(zones: zones)
  }

  private mutating func record(changes: ZoneRecordChanges) {
    let name = changes.zone.zoneName
    var entry = entries[name] ?? Entry()
    entry.zone = changes.zone
    entry.records.append(contentsOf: changes.records)
    entry.syncToken = changes.syncToken
    entries[name] = entry
  }

  private mutating func record(failure: ZoneOperationFailure) {
    var entry = entries[failure.zoneName] ?? Entry()
    entry.failure = failure
    entries[failure.zoneName] = entry
  }
}

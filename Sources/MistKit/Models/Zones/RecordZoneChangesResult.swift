//
//  RecordZoneChangesResult.swift
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

/// Result from fetching record zone changes (`changes/zone`).
///
/// Carries one entry per requested zone — either that zone's record changes or
/// a zone fetch error. There is no top-level sync token: each zone paginates
/// independently via ``ZoneRecordChanges/syncToken`` and
/// ``ZoneRecordChanges/moreComing``.
public struct RecordZoneChangesResult: Sendable {
  /// The per-zone outcomes, in the order CloudKit returned them.
  public let zones: [ZoneRecordChangesResult]

  /// The zones whose changes were fetched successfully.
  public var changes: [ZoneRecordChanges] {
    zones.compactMap { result in
      guard case .success(let changes) = result else { return nil }
      return changes
    }
  }

  /// The per-zone failures, dropping the successes.
  public var failures: [ZoneOperationFailure] {
    zones.compactMap { result in
      guard case .failure(let failure) = result else { return nil }
      return failure
    }
  }

  /// Whether any successfully-fetched zone reports more changes to request.
  public var moreComing: Bool {
    changes.contains { $0.moreComing }
  }

  /// Initialize a record zone changes result.
  public init(zones: [ZoneRecordChangesResult]) {
    self.zones = zones
  }

  internal init(
    from response: Components.Schemas.RecordZoneChangesResponse
  ) throws(ConversionError) {
    var zones: [ZoneRecordChangesResult] = []
    for zone in response.zones ?? [] {
      zones.append(try ZoneRecordChangesResult(from: zone))
    }
    self.init(zones: zones)
  }
}

//
//  DatabaseChangesResult.swift
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

/// Result from fetching database changes (`changes/database`).
///
/// Reports which record zones in the database changed since the provided sync
/// token, along with a new sync token for subsequent fetches. This is the
/// current replacement for the deprecated `zones/changes` operation modeled by
/// ``ZoneChangesResult``.
///
/// Follow up with ``CloudKitService/fetchRecordZoneChanges(zones:database:)``
/// to fetch the record changes within each returned zone.
public struct DatabaseChangesResult: Sendable {
  /// The per-zone outcomes, in the order CloudKit returned them. Each entry is
  /// either a changed zone or a zone fetch error.
  public let zones: [ZoneChangeResult]
  /// Token to use for the next fetch to get incremental changes.
  public let syncToken: String?
  /// Whether more changes are available.
  public let moreComing: Bool

  /// The zones that changed, dropping any per-zone failures.
  ///
  /// Use ``zones`` directly when the failures matter.
  public var changedZones: [ZoneInfo] {
    zones.compactMap { result in
      guard case .success(let zone) = result else { return nil }
      return zone
    }
  }

  /// The per-zone failures, dropping the successes.
  public var failures: [ZoneOperationFailure] {
    zones.compactMap { result in
      guard case .failure(let failure) = result else { return nil }
      return failure
    }
  }

  /// Initialize a database changes result.
  public init(
    zones: [ZoneChangeResult],
    syncToken: String?,
    moreComing: Bool = false
  ) {
    self.zones = zones
    self.syncToken = syncToken
    self.moreComing = moreComing
  }

  internal init(
    from response: Components.Schemas.DatabaseChangesResponse
  ) throws(ConversionError) {
    var zones: [ZoneChangeResult] = []
    for zone in response.zones ?? [] {
      zones.append(try ZoneChangeResult(from: zone))
    }
    self.init(
      zones: zones,
      syncToken: response.syncToken,
      moreComing: response.moreComing ?? false
    )
  }
}

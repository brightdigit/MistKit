//
//  ZoneRecordChanges.swift
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

/// The record changes within a single zone, returned by `changes/zone`.
///
/// Unlike ``RecordChangesResult`` (whose sync token covers the whole request),
/// `changes/zone` returns a sync token and `moreComing` flag *per zone*, so
/// each zone is paginated independently.
public struct ZoneRecordChanges: Sendable {
  /// The zone these changes belong to.
  public let zone: ZoneInfo
  /// Records that changed (created, updated, or deleted) in this zone.
  public let records: [RecordInfo]
  /// Token to use for the next fetch of this zone's changes.
  public let syncToken: String?
  /// Whether more changes are available for this zone.
  public let moreComing: Bool

  /// Initialize a zone's record changes.
  public init(
    zone: ZoneInfo,
    records: [RecordInfo],
    syncToken: String?,
    moreComing: Bool = false
  ) {
    self.zone = zone
    self.records = records
    self.syncToken = syncToken
    self.moreComing = moreComing
  }

  internal init(
    from result: Components.Schemas.RecordZoneChangesZoneResult
  ) throws(ConversionError) {
    var records: [RecordInfo] = []
    for record in result.records ?? [] {
      records.append(try RecordInfo(from: record))
    }
    self.init(
      zone: try ZoneInfo(fromZoneID: result.zoneID),
      records: records,
      syncToken: result.syncToken,
      moreComing: result.moreComing ?? false
    )
  }
}

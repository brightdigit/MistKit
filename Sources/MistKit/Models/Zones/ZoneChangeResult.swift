//
//  ZoneChangeResult.swift
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

/// The outcome for a single zone in a `changes/database` or `zones/modify`
/// response.
///
/// Each entry in the response's `zones` array is either a zone or a zone fetch
/// error, so a failure on one zone never discards the zones that succeeded.
public typealias ZoneChangeResult = OperationResult<ZoneInfo, ZoneTarget>

extension OperationResult where Success == ZoneInfo, Target == ZoneTarget {
  /// Converts a per-zone entry from a `changes/database` response.
  internal init(
    from item: Components.Schemas.DatabaseChangesResponse.zonesPayloadPayload
  ) throws(ConversionError) {
    switch item {
    case .ZoneFetchFailure(let failure):
      self = .failure(try ZoneOperationFailure(from: failure))
    case .DatabaseChangedZone(let zone):
      self = .success(
        try ZoneInfo(
          fromZoneID: zone.zoneID,
          deleted: zone.deleted
        )
      )
    }
  }

  /// Converts a per-zone entry from a `zones/modify` response.
  ///
  /// `zones/modify` returns the full Zone dictionary on success — unlike
  /// `changes/database`, which returns only the `zoneID` — so the zone-level
  /// `syncToken`/`atomic` metadata carries through.
  internal init(
    from item: Components.Schemas.ZonesModifyResponse.zonesPayloadPayload
  ) throws(ConversionError) {
    switch item {
    case .ZoneFetchFailure(let failure):
      self = .failure(try ZoneOperationFailure(from: failure))
    case .Zone(let zone):
      self = .success(try ZoneInfo(from: zone))
    }
  }
}

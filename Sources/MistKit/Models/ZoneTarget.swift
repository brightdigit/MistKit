//
//  ZoneTarget.swift
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

/// Phantom target tagging an ``OperationFailure`` (or ``OperationResult``) as
/// belonging to a per-zone CloudKit batch (`changes/database`, `changes/zone`).
public enum ZoneTarget: OperationFailureTarget {
  /// Lifts a per-zone failure into ``CloudKitError/zoneOperationFailed(_:)``.
  public static func wrap(
    _ failure: OperationFailure<ZoneTarget>
  ) -> CloudKitError {
    .zoneOperationFailed(failure)
  }
}

extension OperationFailure where Target == ZoneTarget {
  /// The zone name of the zone the operation failed on.
  ///
  /// A named alias for ``OperationFailure/identifier`` scoped to the zone
  /// target, matching the `zoneID.zoneName` wire field. CloudKit's zone-fetch
  /// error dictionary identifies the failed item by `zoneID` rather than a
  /// flat string, so the zone *name* is used as the identifier.
  public var zoneName: String { identifier }

  /// Builds a per-zone failure from the generated `ZoneFetchFailure` schema.
  ///
  /// Unlike `RecordOperationFailure`/`SubscriptionOperationFailure` — which
  /// compose `OperationFailureCommon` via `allOf` and carry a flat required
  /// string identifier — CloudKit's zone-fetch error dictionary nests its
  /// identifier in an optional `zoneID`. A missing `zoneID`/`zoneName` is a
  /// conversion failure (consistent with ``ZoneInfo/init(fromZoneID:)``)
  /// rather than a silently-dropped error entry.
  internal init(from schema: Components.Schemas.ZoneFetchFailure) throws(ConversionError) {
    guard let zoneID = schema.zoneID else {
      try ConversionError.zoneMissingID.reportAndThrow()
    }
    guard let zoneName = zoneID.zoneName else {
      try ConversionError.zoneMissingName.reportAndThrow()
    }
    self.init(
      identifier: zoneName,
      common: Components.Schemas.OperationFailureCommon(
        serverErrorCode: schema.serverErrorCode,
        reason: schema.reason,
        retryAfter: schema.retryAfter,
        uuid: schema.uuid,
        redirectURL: schema.redirectURL
      )
    )
  }
}

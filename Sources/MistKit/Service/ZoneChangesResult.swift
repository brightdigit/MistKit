//
//  ZoneChangesResult.swift
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

/// Result from fetching zone changes
///
/// Contains zones that have changed since the provided sync token,
/// along with a new sync token for subsequent fetches.
public struct ZoneChangesResult: Sendable {
  /// Zones that have changed
  public let zones: [ZoneInfo]
  /// Token to use for next fetch to get incremental changes
  public let syncToken: String?

  /// Initialize a zone changes result
  public init(
    zones: [ZoneInfo],
    syncToken: String?
  ) {
    self.zones = zones
    self.syncToken = syncToken
  }

  internal init(from response: Components.Schemas.ZoneChangesResponse) {
    self.zones = response.zones?.compactMap { zonePayload in
      guard let zoneID = zonePayload.zoneID else {
        return nil
      }
      return ZoneInfo(
        zoneName: zoneID.zoneName ?? "Unknown",
        ownerRecordName: zoneID.ownerName,
        capabilities: []  // CloudKit Web Services zone-changes responses omit capabilities
      )
    } ?? []
    self.syncToken = response.syncToken
  }
}

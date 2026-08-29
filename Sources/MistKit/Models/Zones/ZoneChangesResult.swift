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

internal import MistKitOpenAPI

/// Result from fetching zone changes.
///
/// Contains zones that have changed since the provided sync token,
/// along with a new sync token for subsequent fetches.
public struct ZoneChangesResult: Codable, Sendable {
  /// Zones that have changed
  public let zones: [ZoneInfo]
  /// Token to use for next fetch to get incremental changes.
  ///
  /// Carried on the wire as `metaSyncToken` — `zones/changes` is the one
  /// change-tracking operation that does not name its token `syncToken`
  /// (issue #430). The Swift name is unchanged.
  public let syncToken: String?
  /// Whether more changes are available (for large zone change sets)
  public let moreComing: Bool

  /// Initialize a zone changes result
  public init(
    zones: [ZoneInfo],
    syncToken: String?,
    moreComing: Bool = false
  ) {
    self.zones = zones
    self.syncToken = syncToken
    self.moreComing = moreComing
  }

  internal init(from response: Components.Schemas.ZoneChangesResponse) throws(ConversionError) {
    var zones: [ZoneInfo] = []
    for zone in response.zones ?? [] {
      zones.append(try ZoneInfo(from: zone))
    }
    self.zones = zones
    self.syncToken = response.metaSyncToken
    self.moreComing = response.moreComing ?? false
  }
}

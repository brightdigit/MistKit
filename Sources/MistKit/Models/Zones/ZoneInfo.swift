//
//  ZoneInfo.swift
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

/// Zone information from CloudKit
public struct ZoneInfo: Codable, Sendable {
  /// The zone name
  public let zoneName: String
  /// The owner record name
  public let ownerRecordName: String?
  /// The zone capabilities.
  /// Note: always empty — CloudKit Web Services zone responses do not include
  /// capabilities in the current OpenAPI schema.
  public let capabilities: [String]

  /// Initialize zone information
  public init(zoneName: String, ownerRecordName: String?, capabilities: [String]) {
    self.zoneName = zoneName
    self.ownerRecordName = ownerRecordName
    self.capabilities = capabilities
  }

  /// Convert a CloudKit zone payload's `zoneID` into a `ZoneInfo`.
  ///
  /// All zone responses (`list`/`lookup`/`modify`/`changes`) expose an optional
  /// `zoneID`; a missing `zoneID` or `zoneName` is a conversion failure (logged,
  /// asserted in DEBUG, and thrown) rather than a silently-dropped zone.
  ///
  /// The optionality is *not* tightened to `required` in `openapi.yaml` on
  /// purpose: `ZoneID` is one shared schema reused across request bodies (where
  /// callers legitimately send a bare `zoneName` with no resolved `zoneID`) and
  /// response bodies. Making the fields required would break request encoding
  /// and make the generated decoder reject otherwise-valid payloads, so the
  /// response-side "must be present" rule is enforced here at the domain
  /// boundary instead.
  internal init(fromZoneID zoneID: Components.Schemas.ZoneID?) throws(ConversionError) {
    guard let zoneID else {
      try ConversionError.zoneMissingID.reportAndThrow()
    }
    guard let zoneName = zoneID.zoneName else {
      try ConversionError.zoneMissingName.reportAndThrow()
    }
    self.init(
      zoneName: zoneName,
      ownerRecordName: zoneID.ownerName,
      capabilities: []
    )
  }
}

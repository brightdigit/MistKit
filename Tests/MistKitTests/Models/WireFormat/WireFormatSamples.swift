//
//  WireFormatSamples.swift
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

@testable import MistKit

/// Records shaped like Mistico's Codecs golden samples (`specimen-1`, `specimen-2`).
internal enum WireFormatSamples {
  internal static let teams = ZoneID(zoneName: "Teams", ownerName: "_owner1")

  /// Every field type, one list of each shape, an empty list and stamps.
  internal static let specimen = RecordInfo(
    recordName: "specimen-1",
    zoneID: .defaultZone,
    recordType: "Specimen",
    recordChangeTag: "tag-1",
    fields: [
      "count": .int64(.value(42)),
      "empty": .string(.list([])),
      "friends": .reference(
        .list([
          Reference(recordName: "player-ben"),
          Reference(recordName: "player-chen", zoneID: teams),
        ])
      ),
      "notes": .string(.value("Line one\nLine two\t\"quoted\"")),
      "owner": .reference(.value(Reference(recordName: "player-ana", action: .deleteSelf))),
      "payload": .bytes(.value(Data([0x00, 0xFF, 0x10, 0x80]))),
      "photo": .asset(
        .value(
          Asset(
            fileChecksum: "abc123",
            size: 2_048,
            downloadURL: "https://cvws.icloud-content.com/B/abc/photo.jpg?o=1&e=2"
          )
        )
      ),
      "ratio": .double(.value(0.125)),
      "seenAt": .date(.value(Date(timeIntervalSince1970: 1_790_000_000.5))),
      "stops": .location(.list([Location(latitude: 1.5, longitude: -2.25)])),
      "tags": .string(.list(["alpha", "β, gamma"])),
      "title": .string(.value("Émile & “Zoë”, 東京 🚀")),
      "venue": .location(
        .value(Location(latitude: 53.3498, longitude: -6.2603, horizontalAccuracy: 5))
      ),
    ],
    created: RecordTimestamp(
      timestamp: Date(timeIntervalSince1970: 1_789_000_000),
      userRecordName: "_creator"
    ),
    modified: RecordTimestamp(timestamp: Date(timeIntervalSince1970: 1_790_000_000))
  )

  /// A plain record.
  internal static let plain = RecordInfo(
    recordName: "specimen-2",
    zoneID: .defaultZone,
    recordType: "Specimen",
    recordChangeTag: "tag-2",
    fields: ["count": .int64(.value(-7)), "title": .string(.value("Plain"))]
  )
}

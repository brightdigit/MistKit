//
//  ZoneMetadataTests+ZoneInfoConversionEdgeCases.swift
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
internal import Testing

@testable import MistKit
@testable import MistKitOpenAPI

// Omitted on Windows × Swift 6.2: emit-module tip-over (see .claude/docs/research/windows-6.2-ci-failure-462.md).
#if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
  extension ZoneMetadataTests {
    /// Edge-case decoding for ``ZoneInfo`` conversion.
    @Suite("ZoneInfo Conversion Edge Cases")
    internal struct ZoneInfoConversionEdgeCases {
      private static func decodeZone(_ json: String) throws -> Components.Schemas.Zone {
        try JSONDecoder().decode(Components.Schemas.Zone.self, from: Data(json.utf8))
      }

      @Test("atomic decodes false without collapsing into nil")
      internal func atomicFalseIsPreserved() throws {
        let zone = try Self.decodeZone(
          """
          { "zoneID": { "zoneName": "Articles" }, "atomic": false }
          """
        )

        let info = try ZoneInfo(from: zone)

        #expect(info.atomic == false)
      }

      @Test("ZoneInfo still throws when the zone payload has no zoneName")
      internal func missingZoneNameThrows() throws {
        let zone = try Self.decodeZone(
          """
          { "zoneID": { "ownerRecordName": "_defaultOwner" }, "atomic": true }
          """
        )

        ConversionFailureReporter.$assertionHandler.withValue(
          { _, _, _ in },
          operation: {
            #expect(throws: ConversionError.self) {
              _ = try ZoneInfo(from: zone)
            }
          }
        )
      }
    }
  }

#endif

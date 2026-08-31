//
//  ZoneMetadataTests.swift
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

extension ZoneMetadataTests {
  /// Conversion of a `Zone` payload into the domain `ZoneInfo`.
  @Suite("ZoneInfo Conversion")
  internal struct ZoneInfoConversion {
    /// Decode a JSON zone payload into the generated `Zone` schema type.
    internal static func decodeZone(_ json: String) throws -> Components.Schemas.Zone {
      try JSONDecoder().decode(Components.Schemas.Zone.self, from: Data(json.utf8))
    }

    @Test("Zone payload decodes syncToken and atomic")
    internal func zoneDecodesMetadata() throws {
      let zone = try Self.decodeZone(
        """
        {
          "zoneID": { "zoneName": "Articles", "ownerRecordName": "_defaultOwner" },
          "syncToken": "AQAAAAAAAAAB",
          "atomic": true
        }
        """
      )

      #expect(zone.zoneID?.zoneName == "Articles")
      #expect(zone.syncToken == "AQAAAAAAAAAB")
      #expect(zone.atomic == true)
    }

    @Test("ZoneInfo carries syncToken and atomic from a Zone payload")
    internal func zoneInfoCarriesMetadata() throws {
      let zone = try Self.decodeZone(
        """
        {
          "zoneID": { "zoneName": "Articles", "ownerRecordName": "_defaultOwner" },
          "syncToken": "AQAAAAAAAAAB",
          "atomic": true
        }
        """
      )

      let info = try ZoneInfo(from: zone)

      #expect(info.zoneName == "Articles")
      #expect(info.ownerRecordName == "_defaultOwner")
      #expect(info.syncToken == "AQAAAAAAAAAB")
      #expect(info.atomic == true)
      #expect(info.deleted == false)
    }

    @Test(
      "ZoneInfo decodes live-shaped change-feed payload with ownerRecordName, zoneType, and deleted"
    )
    internal func zoneInfoDecodesLiveChangeFeedShape() throws {
      let zone = try Self.decodeZone(
        """
        {
          "zoneID": {
            "zoneName": "WebChangeTest",
            "ownerRecordName": "_aca0fa3547ae9f9cd1f7e25fed948a20",
            "zoneType": "REGULAR_CUSTOM_ZONE"
          },
          "deleted": true
        }
        """
      )

      let info = try ZoneInfo(from: zone)

      #expect(info.zoneName == "WebChangeTest")
      #expect(info.ownerRecordName == "_aca0fa3547ae9f9cd1f7e25fed948a20")
      #expect(info.zoneType == "REGULAR_CUSTOM_ZONE")
      #expect(info.deleted == true)
    }

    @Test("Absent deleted defaults to false rather than collapsing into nil")
    internal func absentDeletedDefaultsFalse() throws {
      let zone = try Self.decodeZone(
        """
        {
          "zoneID": { "zoneName": "Articles", "ownerRecordName": "_defaultOwner" }
        }
        """
      )

      let info = try ZoneInfo(from: zone)

      #expect(info.deleted == false)
    }

    @Test("DatabaseChangedZone tombstone surfaces deleted on ZoneInfo")
    internal func databaseChangedZoneDeletedSurfaces() throws {
      let item = try JSONDecoder().decode(
        Components.Schemas.DatabaseChangesResponse.zonesPayloadPayload.self,
        from: Data(
          """
          {
            "zoneID": {
              "zoneName": "WebChangeTest",
              "ownerRecordName": "_aca0fa3547ae9f9cd1f7e25fed948a20",
              "zoneType": "REGULAR_CUSTOM_ZONE"
            },
            "deleted": true
          }
          """.utf8
        )
      )

      let result = try ZoneChangeResult(from: item)
      let zone = try result.get()

      #expect(zone.zoneName == "WebChangeTest")
      #expect(zone.ownerRecordName == "_aca0fa3547ae9f9cd1f7e25fed948a20")
      #expect(zone.zoneType == "REGULAR_CUSTOM_ZONE")
      #expect(zone.deleted == true)
    }

    @Test("Absent metadata stays nil rather than defaulting")
    internal func absentMetadataStaysNil() throws {
      let zone = try Self.decodeZone(
        """
        { "zoneID": { "zoneName": "Articles" } }
        """
      )

      let info = try ZoneInfo(from: zone)

      // `atomic` must stay nil so "absent" remains distinguishable from
      // an explicit `false`.
      #expect(info.syncToken == nil)
      #expect(info.atomic == nil)
      #expect(info.zoneName == "Articles")
    }

    @Test("atomic decodes false without collapsing into nil")
    internal func atomicFalseIsPreserved() throws {
      let zone = try Self.decodeZone(
        """
        { "zoneID": { "zoneName": "Articles" }, "atomic": false }
        """
      )

      let info = try ZoneInfo(from: zone)

      #expect(try #require(info.atomic) == false)
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

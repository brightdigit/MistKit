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
  /// Decoding of the new zone metadata across every zone response shape.
  @Suite("Responses")
  internal struct Responses {
    @Test("ZonesListResponse decodes zone metadata")
    internal func listResponseDecodesMetadata() throws {
      let response = try JSONDecoder().decode(
        Components.Schemas.ZonesListResponse.self,
        from: Data(
          """
          {
            "zones": [
              {
                "zoneID": { "zoneName": "Articles" },
                "syncToken": "list-token",
                "atomic": true
              }
            ]
          }
          """.utf8
        )
      )

      let zone = try #require(response.zones?.first)
      #expect(zone.syncToken == "list-token")
      #expect(zone.atomic == true)
    }

    @Test("ZonesModifyResponse decodes zone metadata")
    internal func modifyResponseDecodesMetadata() throws {
      let response = try JSONDecoder().decode(
        Components.Schemas.ZonesModifyResponse.self,
        from: Data(
          """
          {
            "zones": [
              {
                "zoneID": { "zoneName": "Articles" },
                "syncToken": "modify-token",
                "atomic": false
              }
            ]
          }
          """.utf8
        )
      )

      let entry = try #require(response.zones?.first)
      guard case .Zone(let zone) = entry else {
        Issue.record("expected the success variant, got \(entry)")
        return
      }
      #expect(zone.syncToken == "modify-token")
      #expect(zone.atomic == false)
    }

    @Test("ZoneChangesResponse decodes per-zone metadata alongside the top-level token")
    internal func changesResponseDecodesMetadata() throws {
      let response = try JSONDecoder().decode(
        Components.Schemas.ZoneChangesResponse.self,
        from: Data(
          """
          {
            "zones": [
              {
                "zoneID": { "zoneName": "Articles" },
                "syncToken": "zone-level-token",
                "atomic": true
              }
            ],
            "metaSyncToken": "top-level-token",
            "moreComing": true
          }
          """.utf8
        )
      )

      let result = try ZoneChangesResult(from: response)

      // The per-zone token and the response-level token are distinct values.
      #expect(result.syncToken == "top-level-token")
      #expect(result.moreComing)
      let zone = try #require(result.zones.first)
      #expect(zone.syncToken == "zone-level-token")
      #expect(zone.atomic == true)
    }

    @Test("ZonesLookupResponse decodes zone metadata")
    internal func lookupResponseDecodesMetadata() throws {
      let response = try JSONDecoder().decode(
        Components.Schemas.ZonesLookupResponse.self,
        from: Data(
          """
          {
            "zones": [
              {
                "zoneID": { "zoneName": "Articles", "ownerRecordName": "_defaultOwner" },
                "syncToken": "lookup-token",
                "atomic": true
              }
            ]
          }
          """.utf8
        )
      )

      let zone = try #require(response.zones?.first)
      let info = try ZoneInfo(from: zone)
      #expect(info.syncToken == "lookup-token")
      #expect(info.atomic == true)
    }

    @Test("ZoneOperation encodes only operationType and zoneID")
    internal func zoneOperationEncodesDocumentedKeysOnly() throws {
      // Apple documents the operation's `zone` as having "a single zoneID key",
      // so no create options are emitted (see issue #386).
      let operation = Components.Schemas.ZoneOperation(
        from: .create(ZoneID(zoneName: "Articles"))
      )

      let data = try JSONEncoder().encode(operation)
      let object = try #require(
        try JSONSerialization.jsonObject(with: data) as? [String: Any]
      )

      #expect(object["operationType"] as? String == "create")
      let zone = try #require(object["zone"] as? [String: Any])
      #expect(Set(zone.keys) == ["zoneID"])
      let zoneID = try #require(zone["zoneID"] as? [String: Any])
      #expect(zoneID["zoneName"] as? String == "Articles")
    }
  }
}

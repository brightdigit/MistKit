//
//  ZoneLookupTests.swift
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

/// Zone-scoped lookups and record zones (MistKit #497).
@Suite("Zone lookup")
internal struct ZoneLookupTests {
  @Test("lookupRecords sends the zone and records keep the zone CloudKit returns")
  internal func lookupInZone() async throws {
    let response = #"""
      {"records":[{"recordName":"n1","recordType":"Note",
        "zoneID":{"zoneName":"Teams","ownerRecordName":"_owner1"},"fields":{}}]}
      """#
    let transport = RecordingTransport(response: .success(body: Data(response.utf8)))
    let service = try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(
        apiAuth: APICredentials(
          apiToken: TestConstants.apiToken,
          webAuthToken: TestConstants.webAuthToken
        )
      ),
      transport: transport
    )
    let teams = ZoneID(zoneName: "Teams", ownerName: "_owner1")
    let results = try await service.lookupAllRecords(
      recordNames: ["n1"],
      zoneID: teams,
      database: .private
    )
    let body = try #require(await transport.sent.first?.body)
    let json = try #require(
      try JSONSerialization.jsonObject(with: body) as? [String: Any]
    )
    let zone = try #require(json["zoneID"] as? [String: Any])
    #expect(zone["zoneName"] as? String == "Teams")
    #expect(zone["ownerRecordName"] as? String == "_owner1")
    guard case .success(let record) = try #require(results.first) else {
      Issue.record("expected a record")
      return
    }
    #expect(record.zoneID == teams)
  }
}

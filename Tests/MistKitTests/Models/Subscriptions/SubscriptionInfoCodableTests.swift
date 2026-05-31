//
//  SubscriptionInfoCodableTests.swift
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

@Suite("SubscriptionInfo Codable")
internal struct SubscriptionInfoCodableTests {
  /// CloudKit collapses a database-wide subscription into
  /// `subscriptionType: zone` with `zoneWide: true` and no `zoneID`, so the
  /// decoder must recover it as `.database`.
  @Test("decodes a zoneWide zone subscription as .database")
  internal func decodesDatabase() throws {
    let json = #"""
      { "subscriptionType": "zone", "zoneWide": true, "subscriptionID": "db-1" }
      """#

    let decoded = try JSONDecoder().decode(SubscriptionInfo.self, from: Data(json.utf8))

    #expect(decoded.subscriptionID == "db-1")
    #expect(decoded.subscriptionType == .zone)
    #expect(decoded.zoneID == nil)
    guard case .database = decoded.kind else {
      Issue.record("expected .database kind, got \(decoded.kind)")
      return
    }
  }

  @Test("encodes .database as zoneWide:true with no zoneID")
  internal func encodesDatabase() throws {
    let info = SubscriptionInfo.database(subscriptionID: "db-1")

    let data = try JSONEncoder().encode(info)
    let object = try #require(
      JSONSerialization.jsonObject(with: data) as? [String: Any]
    )

    #expect(object["subscriptionType"] as? String == "zone")
    #expect(object["zoneWide"] as? Bool == true)
    #expect(object["zoneID"] == nil)
  }

  @Test("round-trips a .database subscription through Codable")
  internal func databaseRoundTrips() throws {
    let info = SubscriptionInfo.database(subscriptionID: "db-1")

    let data = try JSONEncoder().encode(info)
    let decoded = try JSONDecoder().decode(SubscriptionInfo.self, from: data)

    #expect(decoded.subscriptionID == "db-1")
    guard case .database = decoded.kind else {
      Issue.record("expected .database kind, got \(decoded.kind)")
      return
    }
  }
}

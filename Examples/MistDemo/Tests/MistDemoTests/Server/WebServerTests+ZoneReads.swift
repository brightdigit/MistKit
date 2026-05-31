//
//  WebServerTests+ZoneReads.swift
//  MistDemoTests
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

#if canImport(Hummingbird)
  internal import Foundation
  internal import HTTPTypes
  internal import Hummingbird
  internal import HummingbirdTesting
  internal import MistKit
  internal import Testing

  @testable import MistDemoKit

  extension WebServerTests {
    private struct ZonesPayload: Decodable {
      let zones: [ZoneInfo]
    }

    private struct ZoneChangesPayload: Decodable {
      let zones: [ZoneInfo]
      let syncToken: String?
      let moreComing: Bool
    }

    @Test("POST /api/zones/list forwards the database to the backend")
    internal func zonesListForwards() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/zones/list",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: #"{"database":"private"}"#)
        ) { response in
          #expect(response.status == .ok)
          let payload = try JSONDecoder().decode(
            ZonesPayload.self,
            from: Data(response.body.readableBytesView)
          )
          #expect(payload.zones.first?.zoneName == "_defaultZone")
        }
      }

      let captured = await fixture.backend.lastListZones
      #expect(captured?.database == .private)
    }

    @Test("POST /api/zones/list returns 401 without a captured auth token")
    internal func zonesListRequiresAuth() async throws {
      let fixture = Self.makeFixture(authenticated: false)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/zones/list",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: #"{"database":"private"}"#)
        ) { response in
          #expect(response.status == .unauthorized)
        }
      }
    }

    @Test("POST /api/zones/lookup forwards zone names to the backend")
    internal func zonesLookupForwards() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let jsonBody = #"{"database":"private","zoneNames":["Articles","Archive"]}"#

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/zones/lookup",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
          let payload = try JSONDecoder().decode(
            ZonesPayload.self,
            from: Data(response.body.readableBytesView)
          )
          #expect(payload.zones.map(\.zoneName) == ["Articles", "Archive"])
        }
      }

      let captured = await fixture.backend.lastLookupZones
      #expect(captured?.zoneNames == ["Articles", "Archive"])
      #expect(captured?.database == .private)
    }

    @Test("POST /api/zones/lookup returns 401 without a captured auth token")
    internal func zonesLookupRequiresAuth() async throws {
      let fixture = Self.makeFixture(authenticated: false)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/zones/lookup",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: #"{"zoneNames":["Z"]}"#)
        ) { response in
          #expect(response.status == .unauthorized)
        }
      }
    }

    @Test("POST /api/zones/changes forwards the sync token to the backend")
    internal func zonesChangesForwards() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let jsonBody = #"{"database":"private","syncToken":"token-abc"}"#

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/zones/changes",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
          let payload = try JSONDecoder().decode(
            ZoneChangesPayload.self,
            from: Data(response.body.readableBytesView)
          )
          #expect(payload.syncToken == "stub-zone-sync-token")
          #expect(payload.moreComing == false)
        }
      }

      let captured = await fixture.backend.lastZoneChanges
      #expect(captured?.syncToken == "token-abc")
      #expect(captured?.database == .private)
    }

    @Test("POST /api/zones/changes returns 401 without a captured auth token")
    internal func zonesChangesRequiresAuth() async throws {
      let fixture = Self.makeFixture(authenticated: false)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/zones/changes",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: #"{"syncToken":"t"}"#)
        ) { response in
          #expect(response.status == .unauthorized)
        }
      }
    }
  }
#endif

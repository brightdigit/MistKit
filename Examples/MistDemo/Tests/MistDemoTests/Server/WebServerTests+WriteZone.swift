//
//  WebServerTests+WriteZone.swift
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
    @Test("POST /api/records/create rejects zoneOwner without zoneName")
    internal func createRejectsZoneOwnerWithoutZoneName() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/create",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(
            string: #"{"recordType":"Note","fields":{"title":"x"},"zoneOwner":"_abc"}"#
          )
        ) { response in
          #expect(response.status == .badRequest)
        }
      }
    }

    @Test("POST /api/records/create forwards zoneName and zoneOwner to the backend")
    internal func createForwardsZoneSelection() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let jsonBody = """
        {"recordType":"Note","fields":{"title":"Hi"},\
        "zoneName":"Articles","zoneOwner":"_abc123"}
        """

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/create",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
        }
      }

      let captured = await fixture.backend.lastCreate
      #expect(captured?.zone?.zoneName == "Articles")
      #expect(captured?.zone?.zoneOwner == "_abc123")
    }

    @Test("POST /api/records/update rejects zoneOwner without zoneName")
    internal func updateRejectsZoneOwnerWithoutZoneName() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/update",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(
            string: #"{"recordType":"Note","recordName":"n1","fields":{},"zoneOwner":"_abc"}"#
          )
        ) { response in
          #expect(response.status == .badRequest)
        }
      }
    }

    @Test("POST /api/records/update forwards zoneName and zoneOwner to the backend")
    internal func updateForwardsZoneSelection() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let jsonBody = """
        {"recordType":"Note","recordName":"n1","fields":{"title":"Hi"},\
        "recordChangeTag":"t1","zoneName":"Articles","zoneOwner":"_abc123"}
        """

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/update",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
        }
      }

      let captured = await fixture.backend.lastUpdate
      #expect(captured?.zone?.zoneName == "Articles")
      #expect(captured?.zone?.zoneOwner == "_abc123")
    }

    @Test("POST /api/records/delete rejects zoneOwner without zoneName")
    internal func deleteRejectsZoneOwnerWithoutZoneName() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/delete",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(
            string: #"{"recordType":"Note","recordName":"n1","zoneOwner":"_abc"}"#
          )
        ) { response in
          #expect(response.status == .badRequest)
        }
      }
    }

    @Test("POST /api/records/delete forwards zoneName and zoneOwner to the backend")
    internal func deleteForwardsZoneSelection() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let jsonBody = """
        {"recordType":"Note","recordName":"n1","recordChangeTag":"t1",\
        "zoneName":"Articles","zoneOwner":"_abc123"}
        """

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/delete",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
        }
      }

      let captured = await fixture.backend.lastDelete
      #expect(captured?.zone?.zoneName == "Articles")
      #expect(captured?.zone?.zoneOwner == "_abc123")
    }

    @Test("POST /api/assets/upload rejects zoneOwner without zoneName")
    internal func uploadRejectsZoneOwnerWithoutZoneName() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      // Minimal base64 payload ("AQ==" = one byte).
      let jsonBody = """
        {"recordType":"Note","fieldName":"image","data":"AQ==","zoneOwner":"_abc"}
        """

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/assets/upload",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .badRequest)
        }
      }
    }

    @Test("POST /api/assets/upload forwards zoneName and zoneOwner to the backend")
    internal func uploadForwardsZoneSelection() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let jsonBody = """
        {"recordType":"Note","fieldName":"image","data":"AQ==",\
        "zoneName":"Articles","zoneOwner":"_abc123"}
        """

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/assets/upload",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
        }
      }

      let captured = await fixture.backend.lastUploadAsset
      #expect(captured?.zone?.zoneName == "Articles")
      #expect(captured?.zone?.zoneOwner == "_abc123")
    }
  }
#endif

//
//  WebServerTests+Assets.swift
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
    @Test("POST /api/assets/rereference forwards source/target to the backend")
    internal func assetsRereferenceForwards() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let jsonBody = """
        {"database":"private","sourceRecordName":"src-1","assetField":"image",\
        "targetRecordName":"tgt-1","targetAssetField":"image"}
        """

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/assets/rereference",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
        }
      }

      let captured = await fixture.backend.lastRereferenceAsset
      #expect(captured?.sourceRecordName == "src-1")
      #expect(captured?.assetField == "image")
      #expect(captured?.targetRecordName == "tgt-1")
      #expect(captured?.targetAssetField == "image")
      #expect(captured?.database == .private)
    }

    @Test("POST /api/assets/rereference returns 401 without a captured auth token")
    internal func assetsRereferenceRequiresAuth() async throws {
      let fixture = Self.makeFixture(authenticated: false)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/assets/rereference",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(
            string: #"{"sourceRecordName":"a","assetField":"image","targetRecordName":"b"}"#
          )
        ) { response in
          #expect(response.status == .unauthorized)
        }
      }
    }

    @Test("POST /api/assets/upload forwards bytes and metadata to the backend")
    internal func assetsUploadForwards() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let payloadBytes = Data([0xDE, 0xAD, 0xBE, 0xEF])
      let base64 = payloadBytes.base64EncodedString()
      let jsonBody =
        #"{"database":"private","recordType":"Note","fieldName":"image","data":"\#(base64)"}"#

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
      #expect(captured?.recordType == "Note")
      #expect(captured?.fieldName == "image")
      #expect(captured?.recordName == nil)
      #expect(captured?.data == payloadBytes)
      #expect(captured?.database == .private)
    }

    @Test("POST /api/assets/upload returns 401 without a captured auth token")
    internal func assetsUploadRequiresAuth() async throws {
      let fixture = Self.makeFixture(authenticated: false)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/assets/upload",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(
            string: #"{"recordType":"Note","fieldName":"image","data":"AA=="}"#
          )
        ) { response in
          #expect(response.status == .unauthorized)
        }
      }
    }
  }
#endif

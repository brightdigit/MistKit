//
//  WebServerTests+Index.swift
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
  import Foundation
  import HTTPTypes
  import Hummingbird
  import HummingbirdTesting
  import MistKit
  import Testing

  @testable import MistDemoKit

  extension WebServerTests {
    @Test("GET / returns the web demo HTML")
    internal func indexReturnsHtml() async throws {
      let fixture = Self.makeFixture()
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(uri: "/", method: .get) { response in
          #expect(response.status == .ok)
          let body = String(buffer: response.body)
          #expect(body.contains("MistKit Web Demo"))
        }
      }
    }

    @Test("Index HTML wires CloudKit JS as an alternate backend")
    internal func indexExposesCloudKitJsHandlers() async throws {
      let fixture = Self.makeFixture()
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(uri: "/", method: .get) { response in
          #expect(response.status == .ok)
          let body = String(buffer: response.body)
          #expect(body.contains("cdn.apple-cloudkit.com/ck/2/cloudkit.js"))
          #expect(!body.contains("id=\"mode-cloudkitjs\" type=\"button\" disabled"))
          #expect(body.contains("performQuery"))
          #expect(body.contains("saveRecords"))
          #expect(body.contains("deleteRecords"))
          #expect(!body.contains("cloudKitJsNotWired"))
        }
      }
    }

    @Test("Index HTML exposes a public/private database picker")
    internal func indexExposesDatabasePicker() async throws {
      let fixture = Self.makeFixture()
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(uri: "/", method: .get) { response in
          #expect(response.status == .ok)
          let body = String(buffer: response.body)
          #expect(body.contains(#"id="db-private""#))
          #expect(body.contains(#"id="db-public""#))
          #expect(body.contains("publicCloudDatabase"))
          #expect(body.contains("privateCloudDatabase"))
        }
      }
    }
  }
#endif

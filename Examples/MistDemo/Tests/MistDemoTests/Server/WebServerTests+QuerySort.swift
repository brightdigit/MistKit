//
//  WebServerTests+QuerySort.swift
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
    @Test("POST /api/records/query forwards sortBy to the backend")
    internal func queryForwardsSort() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())
      let jsonBody = """
        {"recordType":"Note","sortBy":[\
        {"field":"___modTime","ascending":false}]}
        """

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/query",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: jsonBody)
        ) { response in
          #expect(response.status == .ok)
        }
      }

      let captured = await fixture.backend.lastQuery
      #expect(captured?.sortBy?.count == 1)
      #expect(captured?.sortBy?.first?.field == "___modTime")
      #expect(captured?.sortBy?.first?.ascending == false)
    }

    @Test("POST /api/records/query without sortBy passes nil")
    internal func queryWithoutSortIsNil() async throws {
      let fixture = Self.makeFixture(authenticated: true)
      let app = Application(router: try fixture.server.makeRouter())

      try await app.test(.router) { client in
        try await client.execute(
          uri: "/api/records/query",
          method: .post,
          headers: [.contentType: "application/json"],
          body: ByteBuffer(string: #"{"recordType":"Note"}"#)
        ) { response in
          #expect(response.status == .ok)
        }
      }

      let captured = await fixture.backend.lastQuery
      #expect(captured?.sortBy == nil)
    }
  }
#endif

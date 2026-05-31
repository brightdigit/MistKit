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
  internal import Foundation
  internal import HTTPTypes
  internal import Hummingbird
  internal import HummingbirdTesting
  internal import MistKit
  internal import Testing

  @testable import MistDemoKit

  extension WebServerTests {
    /// Fetch a served document body as a string, asserting a 200.
    ///
    /// The web demo's CSS and JS were extracted out of `index.html` into
    /// `/styles.css` and `/js/*.js` static assets, so the structural HTML,
    /// behavior (JS), and styling (CSS) each live at a distinct URI now.
    private func body(at uri: String) async throws -> String {
      let app = Application(router: try Self.makeFixture().server.makeRouter())
      return try await app.test(.router) { client in
        try await client.execute(uri: uri, method: .get) { response in
          #expect(response.status == .ok)
          return String(buffer: response.body)
        }
      }
    }

    @Test("GET / returns the web demo HTML")
    internal func indexReturnsHtml() async throws {
      let html = try await body(at: "/")
      #expect(html.contains("MistKit Web Demo"))
    }

    @Test("Index HTML wires CloudKit JS as an alternate backend")
    internal func indexExposesCloudKitJsHandlers() async throws {
      let html = try await body(at: "/")
      #expect(html.contains("cdn.apple-cloudkit.com/ck/2/cloudkit.js"))
      #expect(!html.contains("id=\"mode-cloudkitjs\" type=\"button\" disabled"))

      // CloudKit JS primitives now live in the extracted app module.
      let appJs = try await body(at: "/js/app.js")
      #expect(appJs.contains("performQuery"))
      #expect(appJs.contains("saveRecords"))
      #expect(appJs.contains("deleteRecords"))
      #expect(!appJs.contains("cloudKitJsNotWired"))
    }

    @Test("Index HTML exposes a public/private database picker")
    internal func indexExposesDatabasePicker() async throws {
      let html = try await body(at: "/")
      #expect(html.contains(#"id="db-private""#))
      #expect(html.contains(#"id="db-public""#))

      // The picker's wiring to the CloudKit JS database handles is in app.js.
      let appJs = try await body(at: "/js/app.js")
      #expect(appJs.contains("publicCloudDatabase"))
      #expect(appJs.contains("privateCloudDatabase"))
    }

    @Test("Web demo carries the post-database-picker UX additions")
    internal func indexCarriesUxPolish() async throws {
      let css = try await body(at: "/styles.css")
      let appJs = try await body(at: "/js/app.js")
      // 1. Loading state
      #expect(css.contains(".status.loading"))
      #expect(appJs.contains("queryInFlight"))
      #expect(appJs.contains("setQueryControlsDisabled"))
      // 2. Post-create delay
      #expect(appJs.contains("REFRESH_DELAY_MS"))
      #expect(appJs.contains("waiting"))
      // 3. "You" badge wired to the captured user identity
      #expect(appJs.contains("currentUserRecordName"))
      #expect(css.contains("badge-you"))
      #expect(appJs.contains("extractUserRecordName"))
      // 4. Default sort = ___createTime descending
      #expect(
        appJs.contains(
          "currentSort = { field: '___createTime', ascending: false }"
        )
      )
    }
  }
#endif

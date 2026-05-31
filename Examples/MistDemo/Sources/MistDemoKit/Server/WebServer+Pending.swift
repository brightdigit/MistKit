//
//  WebServer+Pending.swift
//  MistDemo
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

  extension WebServer {
    private static func registerPendingPost(
      api: RouterGroup<BasicRequestContext>,
      path: String,
      endpoint: String,
      trackingIssue: Int
    ) {
      let bytes: Data
      do {
        bytes = try PendingStub.responseJSON(
          endpoint: endpoint, trackingIssue: trackingIssue
        )
      } catch {
        // PendingStub.responseJSON encodes a fixed shape; failure here would
        // be a programmer error, not a runtime failure. Crash early so a
        // broken stub doesn't masquerade as a working route.
        preconditionFailure(
          "Failed to encode pending-stub body for \(endpoint): \(error)"
        )
      }
      api.post(RouterPath(path)) { _, _ -> Response in
        Self.jsonResponse(status: .notImplemented, bytes: bytes)
      }
    }

    /// Register 501 stubs for every CloudKit Web Services endpoint not yet
    /// wired to a real handler. Each route returns the shared
    /// `PendingStub.responseJSON` payload so the browser-side panel renders a
    /// structured "pending #N" body. When a route is ready, flip the
    /// corresponding `api.<verb>(...)` registration here to the real handler
    /// (or move it into a dedicated extension file).
    ///
    /// Only one endpoint remains pending — it has **no MistKit wrapper yet**:
    /// - `POST records/resolve` (#41) — `CloudKitService` has no
    ///   `resolveRecords`; `ResolveCommand` likewise only prints a stub.
    ///
    /// Already moved off this list to real handlers: `subscriptions/*`
    /// (#49/#50/#51 → `WebServer+Subscriptions`), `tokens/*`
    /// (#52/#53 → `WebServer+Tokens`), `assets/rereference`
    /// (#31 → `WebServer+Assets`), and the records/zones/users endpoints
    /// (#394 → `WebServer+Records` / `WebServer+Zones` / `WebServer+Users`).
    internal func addPendingEndpoints(
      api: RouterGroup<BasicRequestContext>
    ) {
      Self.registerPendingPost(
        api: api,
        path: "records/resolve",
        endpoint: "records/resolve",
        trackingIssue: 41
      )
    }
  }
#endif

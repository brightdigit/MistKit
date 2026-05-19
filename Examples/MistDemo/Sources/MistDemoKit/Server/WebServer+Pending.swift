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
    /// HTTP verbs the pending registrar supports — only the ones we need.
    internal enum PendingVerb {
      case get
      case post
    }

    /// Register 501 stubs for every CloudKit Web Services endpoint whose
    /// MistKit Swift wrapper hasn't landed yet. Each route returns the
    /// shared `PendingStub.responseJSON` payload so the browser-side panel
    /// renders a structured "pending #N" body. When a tracking issue lands,
    /// flip the corresponding `api.<verb>(...)` registration here to the
    /// real handler (or move it into a dedicated extension file).
    internal func addPendingEndpoints(
      api: RouterGroup<BasicRequestContext>
    ) {
      Self.registerPending(
        api: api,
        verb: .post,
        path: "records/resolve",
        endpoint: "records/resolve",
        trackingIssue: 41
      )
      Self.registerPending(
        api: api,
        verb: .post,
        path: "assets/rereference",
        endpoint: "assets/rereference",
        trackingIssue: 31
      )
      Self.registerPending(
        api: api,
        verb: .get,
        path: "subscriptions",
        endpoint: "subscriptions/list",
        trackingIssue: 49
      )
      Self.registerPending(
        api: api,
        verb: .get,
        path: "subscriptions/:id",
        endpoint: "subscriptions/lookup",
        trackingIssue: 50
      )
      Self.registerPending(
        api: api,
        verb: .post,
        path: "tokens",
        endpoint: "tokens/create",
        trackingIssue: 52
      )
      Self.registerPending(
        api: api,
        verb: .post,
        path: "tokens/register",
        endpoint: "tokens/register",
        trackingIssue: 53
      )
    }

    private static func registerPending(
      api: RouterGroup<BasicRequestContext>,
      verb: PendingVerb,
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
      let handler: @Sendable (Request, BasicRequestContext) async throws -> Response = {
        _, _ -> Response in
        Self.jsonResponse(status: .notImplemented, bytes: bytes)
      }
      switch verb {
      case .get:
        api.get(RouterPath(path), use: handler)
      case .post:
        api.post(RouterPath(path), use: handler)
      }
    }
  }
#endif

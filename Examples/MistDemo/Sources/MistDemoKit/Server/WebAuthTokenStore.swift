//
//  WebAuthTokenStore.swift
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

/// Thread-safe holder for the captured `ckWebAuthToken`.
///
/// The web-demo's `/api/authenticate` route writes here when the browser
/// completes the CloudKit auth flow; the CRUD routes read here on each
/// request to authorize themselves against the captured session.
///
/// `tokenUpdates` yields each captured token so one-shot consumers (e.g.
/// the auth-token command) can await the first emission and shut down.
internal actor WebAuthTokenStore {
  private var token: String?
  private let updatesContinuation: AsyncStream<String>.Continuation
  internal nonisolated let tokenUpdates: AsyncStream<String>

  internal init(token: String? = nil) {
    self.token = token
    var continuation: AsyncStream<String>.Continuation!
    self.tokenUpdates = AsyncStream { continuation = $0 }
    self.updatesContinuation = continuation
  }

  deinit {
    updatesContinuation.finish()
  }

  internal func update(_ token: String) {
    self.token = token
    updatesContinuation.yield(token)
  }

  internal func clear() {
    self.token = nil
  }

  internal var currentToken: String? {
    self.token
  }
}

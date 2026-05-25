//
//  WebCourierPoller.swift
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

#if !os(WASI)
  internal import Foundation

  #if canImport(FoundationNetworking)
    internal import FoundationNetworking
  #endif

  /// Long-polls a CloudKit `webcourierURL` to receive subscription-triggered
  /// notifications without a device or APNs entitlement — the only fully
  /// headless way to observe a push end-to-end.
  ///
  /// - Important: This uses a **dedicated** ephemeral `URLSession`, never the
  ///   CloudKit API `ClientTransport`. The courier host is distinct from
  ///   `api.apple-cloudkit.com`; sharing an HTTP/2 connection across the two
  ///   risks 421 Misdirected Request, the same hazard called out for asset
  ///   uploads in CLAUDE.md.
  internal struct WebCourierPoller {
    private let courierURL: URL
    private let perPollTimeout: TimeInterval
    private let session: URLSession

    /// - Parameters:
    ///   - courierURL: The `webcourierURL` returned by `createAPNsToken`.
    ///   - perPollTimeout: How long a single long-poll request waits before
    ///     the server (or this client) gives up and the caller polls again.
    internal init(courierURL: URL, perPollTimeout: TimeInterval = 30) {
      self.courierURL = courierURL
      self.perPollTimeout = perPollTimeout
      let configuration = URLSessionConfiguration.ephemeral
      configuration.timeoutIntervalForRequest = perPollTimeout + 5
      configuration.waitsForConnectivity = false
      self.session = URLSession(configuration: configuration)
    }

    /// Issue one long-poll request and return whatever the courier responds
    /// with. Returns even on an empty/keepalive body so the caller can decide
    /// whether to poll again.
    internal func pollOnce() async throws -> CourierFrame {
      var request = URLRequest(url: courierURL)
      request.httpMethod = "GET"
      request.timeoutInterval = perPollTimeout
      let (data, response) = try await session.data(for: request)
      let statusCode = (response as? HTTPURLResponse)?.statusCode
      return CourierFrame(statusCode: statusCode, raw: data)
    }

    /// Long-poll repeatedly until a non-empty frame arrives or the task is
    /// cancelled. The caller is expected to wrap this in a bounded timeout
    /// (e.g. ``withTimeout(seconds:operation:)``) so a never-arriving push
    /// can't hang the run.
    internal func waitForFrame() async throws -> CourierFrame {
      while true {
        try Task.checkCancellation()
        let frame = try await pollOnce()
        if !frame.isEmpty {
          return frame
        }
        // Empty body = keepalive/timeout; brief backoff before re-polling.
        try await Task.sleep(for: .milliseconds(250))
      }
    }

    /// A stream of decoded notifications — the Swift mirror of CloudKit JS's
    /// `addNotificationListener`. Re-polls forever and yields each decoded
    /// frame. Finishes when the consuming task is cancelled (e.g. via
    /// `withTimeout`) or rethrows a transport error.
    ///
    /// No de-duplication: the courier is **consume-on-delivery** — each poll
    /// pops exactly one queued notification and never redelivers it (verified
    /// #379). De-duping on `notificationID` would be actively wrong: one change
    /// matching N subscriptions enqueues N notifications that **share** a `nid`
    /// but differ by `sid`, so keying on `nid` would drop the siblings.
    internal func notifications() -> AsyncThrowingStream<CourierNotification, any Error> {
      // Capture only Sendable state; rebuild the poller inside the task so the
      // non-Sendable URLSession never crosses the concurrency boundary.
      let courierURL = self.courierURL
      let perPollTimeout = self.perPollTimeout
      return AsyncThrowingStream { continuation in
        let task = Task {
          let poller = WebCourierPoller(courierURL: courierURL, perPollTimeout: perPollTimeout)
          do {
            while !Task.isCancelled {
              let frame = try await poller.pollOnce()
              guard let notification = frame.notification else {
                // Keepalive/unparseable; brief backoff, then re-poll.
                try await Task.sleep(for: .milliseconds(250))
                continue
              }
              continuation.yield(notification)
            }
            continuation.finish()
          } catch {
            continuation.finish(throwing: error)
          }
        }
        continuation.onTermination = { _ in task.cancel() }
      }
    }
  }
#endif

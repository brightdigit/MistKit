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
  internal import MistKit

  #if canImport(FoundationNetworking)
    internal import FoundationNetworking
  #endif

  /// Long-polls a CloudKit `webcourierURL` to receive subscription-triggered
  /// notifications without a device or APNs entitlement — the only fully
  /// headless way to observe a push end-to-end.
  ///
  /// - Important: The transport defaults to a **dedicated** ephemeral
  ///   `URLSession`, and must **never** be the CloudKit API `ClientTransport`.
  ///   The courier host is distinct from `api.apple-cloudkit.com`; reusing the
  ///   CloudKit transport's HTTP/2 connection pool across the two hosts risks
  ///   **421 Misdirected Request** — the same hazard that makes MistKit upload
  ///   assets through a separate `AssetUploader` closure rather than the shared
  ///   transport (see CLAUDE.md, "Asset Upload Transport Design"). The
  ///   transport is injectable only so tests can drive the poller without a
  ///   live courier, not to share it with the CloudKit client.
  internal struct WebCourierPoller {
    /// A single courier long-poll round-trip: issue the request and return the
    /// body plus response. Defaults to a dedicated ephemeral `URLSession`;
    /// inject only to stub the courier in tests. See the type's 421 note —
    /// never back this with the CloudKit `ClientTransport`.
    internal typealias Transport = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    private let courierURL: URL
    private let perPollTimeout: TimeInterval
    private let transport: Transport?
    private let session: URLSession

    /// - Parameters:
    ///   - courierURL: The `webcourierURL` returned by `createAPNsToken`.
    ///   - perPollTimeout: How long a single long-poll request waits before
    ///     the server (or this client) gives up and the caller polls again.
    ///   - transport: Optional injected round-trip used in place of the
    ///     dedicated `URLSession`. Leave `nil` in production.
    internal init(
      courierURL: URL,
      perPollTimeout: TimeInterval = 30,
      transport: Transport? = nil
    ) {
      self.courierURL = courierURL
      self.perPollTimeout = perPollTimeout
      self.transport = transport
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
      let data: Data
      let response: URLResponse
      if let transport {
        (data, response) = try await transport(request)
      } else {
        (data, response) = try await session.data(for: request)
      }
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
      let transport = self.transport
      return AsyncThrowingStream { continuation in
        let task = Task {
          let poller = WebCourierPoller(
            courierURL: courierURL,
            perPollTimeout: perPollTimeout,
            transport: transport
          )
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

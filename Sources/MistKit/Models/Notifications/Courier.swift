//
//  Courier.swift
//  MistKit
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
  public import Foundation

  /// Long-polls a CloudKit `webcourierURL` to receive subscription-triggered
  /// notifications without a device or APNs entitlement — the only fully
  /// headless way to observe a push end-to-end.
  ///
  /// `Courier` is a namespace: ``pollOnce(courierURL:perPollTimeout:transport:)``
  /// performs a single long-poll and
  /// ``notifications(courierURL:perPollTimeout:transport:)`` streams them. Both
  /// run their HTTP round-trip through a ``Transport``. For the common
  /// `URLSession` case, build a ``WebCourierPoller`` instead — it binds the URL
  /// and a session-backed transport for you.
  public enum Courier {
    /// Closure that performs a single CloudKit web-courier long-poll: issue a
    /// GET to the `webcourierURL` and return the raw HTTP response.
    ///
    /// **⚠️ CRITICAL: Transport Separation Required**
    ///
    /// Custom implementations MUST maintain connection-pool separation from the
    /// CloudKit API:
    /// - Use a transport distinct from the CloudKit API `ClientTransport`
    /// - Do NOT share HTTP/2 connections with `api.apple-cloudkit.com`
    ///
    /// **Why Separate Connection Pools?**
    ///
    /// The web-courier host is distinct from the CloudKit API host
    /// (`api.apple-cloudkit.com`). Reusing the same HTTP/2 connection for both
    /// hosts causes 421 Misdirected Request errors due to HTTP/2's
    /// host-validation rules — the same hazard that makes MistKit upload assets
    /// through a separate ``AssetUploader`` rather than the shared API
    /// transport.
    ///
    /// Returns the raw HTTP response (status code and body) without decoding;
    /// `Courier` decodes the body into a ``CourierNotification``.
    ///
    /// - Parameters:
    ///   - courierURL: The `webcourierURL` to long-poll.
    ///   - timeout: How long a single long-poll request waits before giving up
    ///     so the caller can poll again.
    /// - Returns: Tuple containing the optional HTTP status code and body.
    /// - Throws: Any error that occurs during the poll.
    public typealias Transport =
      @Sendable (_ courierURL: URL, _ timeout: TimeInterval) async throws -> (
        statusCode: Int?, data: Data
      )
  }

  extension Courier {
    /// Issue one long-poll request and decode the result.
    ///
    /// Returns `nil` when the courier responds with an empty/keepalive body or
    /// a body that isn't a recognizable notification, so the caller can decide
    /// whether to poll again.
    ///
    /// - Parameters:
    ///   - courierURL: The `webcourierURL` returned by `createAPNsToken`.
    ///   - perPollTimeout: How long the long-poll request waits before giving
    ///     up so the caller can poll again.
    ///   - transport: The HTTP round-trip used for the poll.
    /// - Returns: The decoded notification, or `nil` for an empty/keepalive or
    ///   unrecognizable body.
    /// - Throws: ``CloudKitError/httpError(statusCode:)`` when the courier
    ///   responds with a non-2xx status (e.g. an expired token), so a
    ///   persistent failure surfaces instead of looping; otherwise any error
    ///   thrown by `transport`.
    public static func pollOnce(
      courierURL: URL,
      perPollTimeout: TimeInterval = 30,
      transport: Transport
    ) async throws -> CourierNotification? {
      let (statusCode, data) = try await transport(courierURL, perPollTimeout)
      if let statusCode, !(200...299).contains(statusCode) {
        throw CloudKitError.httpError(statusCode: statusCode)
      }
      return try? CourierNotification(data: data)
    }

    /// A stream of decoded notifications — the Swift mirror of CloudKit JS's
    /// `addNotificationListener`. Re-polls forever and yields each decoded
    /// notification. Finishes when the consuming task is cancelled (e.g. via a
    /// bounded timeout) or rethrows a transport error.
    ///
    /// No de-duplication: the courier is **consume-on-delivery** — each poll
    /// pops exactly one queued notification and never redelivers it (verified
    /// #379). De-duping on `notificationID` would be actively wrong: one change
    /// matching N subscriptions enqueues N notifications that **share** a `nid`
    /// but differ by `sid`, so keying on `nid` would drop the siblings.
    ///
    /// - Parameters:
    ///   - courierURL: The `webcourierURL` returned by `createAPNsToken`.
    ///   - perPollTimeout: How long each long-poll request waits before
    ///     re-polling.
    ///   - transport: The HTTP round-trip used for each poll.
    /// - Returns: A stream that yields each decoded notification until the
    ///   consuming task is cancelled or `transport` throws.
    public static func notifications(
      courierURL: URL,
      perPollTimeout: TimeInterval = 30,
      transport: @escaping Transport
    ) -> AsyncThrowingStream<CourierNotification, any Error> {
      AsyncThrowingStream { continuation in
        let task = Task {
          do {
            while !Task.isCancelled {
              guard
                let notification = try await pollOnce(
                  courierURL: courierURL,
                  perPollTimeout: perPollTimeout,
                  transport: transport
                )
              else {
                // Keepalive/unparseable; brief backoff, then re-poll.
                try await Task.sleep(nanoseconds: 250_000_000)
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

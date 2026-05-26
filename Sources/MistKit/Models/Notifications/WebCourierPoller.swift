//
//  WebCourierPoller.swift
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

  #if canImport(FoundationNetworking)
    public import FoundationNetworking
  #endif

  /// Binds a `webcourierURL` and a ``Courier/Transport`` so callers can
  /// long-poll for subscription-triggered notifications without a device or
  /// APNs entitlement — the only fully headless way to observe a push
  /// end-to-end.
  ///
  /// Construct it three ways, from lowest- to highest-level:
  /// - ``init(courierURL:perPollTimeout:transport:)`` — supply any
  ///   ``Courier/Transport`` (e.g. an `AsyncHTTPClient`-backed closure, or a
  ///   test stub). Available on every platform.
  /// - ``init(courierURL:perPollTimeout:session:)`` — back the poll with a
  ///   `URLSession` you provide; the session is reused across polls.
  /// - ``init(courierURL:perPollTimeout:configuration:)`` — build a dedicated
  ///   `URLSession` from a configuration that defaults to
  ///   ``ephemeralConfiguration``.
  ///
  /// All work delegates to ``Courier/pollOnce(courierURL:perPollTimeout:transport:)``
  /// and ``Courier/notifications(courierURL:perPollTimeout:transport:)``.
  public struct WebCourierPoller: Sendable {
    /// The default courier session configuration: ephemeral (no persistent
    /// cache or cookies) with `waitsForConnectivity == false`, so a poll fails
    /// fast rather than blocking when connectivity is unavailable. Being a
    /// dedicated session, it keeps the courier's held-open long-poll
    /// connections isolated from `URLSession.shared` and from the CloudKit API
    /// `ClientTransport`.
    public static var ephemeralConfiguration: URLSessionConfiguration {
      let configuration = URLSessionConfiguration.ephemeral
      configuration.waitsForConnectivity = false
      return configuration
    }

    private let courierURL: URL
    private let perPollTimeout: TimeInterval
    private let transport: Courier.Transport

    /// Build a poller from an explicit ``Courier/Transport``.
    ///
    /// - Parameters:
    ///   - courierURL: The `webcourierURL` returned by `createAPNsToken`.
    ///   - perPollTimeout: How long a single long-poll request waits before
    ///     the server (or this client) gives up and the caller polls again.
    ///   - transport: The HTTP round-trip used for each poll.
    public init(
      courierURL: URL,
      perPollTimeout: TimeInterval = 30,
      transport: @escaping Courier.Transport
    ) {
      self.courierURL = courierURL
      self.perPollTimeout = perPollTimeout
      self.transport = transport
    }

    /// Build a poller backed by a `URLSession`, reused across every poll so its
    /// connection pool is shared only among this poller's long-polls.
    ///
    /// - Parameters:
    ///   - courierURL: The `webcourierURL` returned by `createAPNsToken`.
    ///   - perPollTimeout: How long a single long-poll request waits before the
    ///     caller polls again.
    ///   - session: The session used to issue each poll.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public init(
      courierURL: URL,
      perPollTimeout: TimeInterval = 30,
      session: URLSession
    ) {
      self.init(courierURL: courierURL, perPollTimeout: perPollTimeout) { url, timeout in
        try await session.pollCourier(url, timeout: timeout)
      }
    }

    /// Build a poller backed by a dedicated `URLSession` created from
    /// `configuration`.
    ///
    /// - Parameters:
    ///   - courierURL: The `webcourierURL` returned by `createAPNsToken`.
    ///   - perPollTimeout: How long a single long-poll request waits before the
    ///     caller polls again.
    ///   - configuration: The configuration for the dedicated session.
    ///     Defaults to ``ephemeralConfiguration``.
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public init(
      courierURL: URL,
      perPollTimeout: TimeInterval = 30,
      configuration: URLSessionConfiguration = WebCourierPoller.ephemeralConfiguration
    ) {
      self.init(
        courierURL: courierURL,
        perPollTimeout: perPollTimeout,
        session: URLSession(configuration: configuration)
      )
    }

    /// Issue one long-poll request and decode the result. Returns `nil` on an
    /// empty/keepalive or unrecognizable body so the caller can poll again.
    public func pollOnce() async throws -> CourierNotification? {
      try await Courier.pollOnce(
        courierURL: courierURL,
        perPollTimeout: perPollTimeout,
        transport: transport
      )
    }

    /// A stream of decoded notifications. Re-polls forever and yields each
    /// decoded notification until the consuming task is cancelled.
    public func notifications() -> AsyncThrowingStream<CourierNotification, any Error> {
      Courier.notifications(
        courierURL: courierURL,
        perPollTimeout: perPollTimeout,
        transport: transport
      )
    }
  }
#endif

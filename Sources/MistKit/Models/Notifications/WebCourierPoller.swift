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

  /// A convenience wrapper around the ``Courier`` namespace that binds a
  /// `webcourierURL` and per-poll timeout once, so callers can poll without
  /// repeating them on every call.
  ///
  /// All work delegates to ``Courier/pollOnce(courierURL:perPollTimeout:transport:)``
  /// and ``Courier/notifications(courierURL:perPollTimeout:transport:)``.
  @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
  public struct WebCourierPoller: Sendable {
    private let courierURL: URL
    private let perPollTimeout: TimeInterval
    private let transport: Courier.Transport?

    /// - Parameters:
    ///   - courierURL: The `webcourierURL` returned by `createAPNsToken`.
    ///   - perPollTimeout: How long a single long-poll request waits before
    ///     the server (or this client) gives up and the caller polls again.
    ///   - transport: Optional injected round-trip used in place of the
    ///     default `URLSession`. Leave `nil` to use the default.
    public init(
      courierURL: URL,
      perPollTimeout: TimeInterval = 30,
      transport: Courier.Transport? = nil
    ) {
      self.courierURL = courierURL
      self.perPollTimeout = perPollTimeout
      self.transport = transport
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

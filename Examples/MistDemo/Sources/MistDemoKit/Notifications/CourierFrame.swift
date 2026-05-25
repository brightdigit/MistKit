//
//  CourierFrame.swift
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

  /// A single raw response from a CloudKit web-courier long-poll.
  ///
  /// The web-courier wire format is **not** documented in Apple's CloudKit Web
  /// Services REST reference — CloudKit JS consumes it internally — so this
  /// frame preserves the unparsed bytes alongside a typed decode. See #379
  /// for the verified payload shape.
  internal struct CourierFrame: Sendable {
    /// HTTP status returned by the courier endpoint, when available.
    internal let statusCode: Int?
    /// The raw response body, preserved verbatim for wire-format discovery.
    internal let raw: Data

    /// The body decoded as UTF-8 text, for logging during the discovery spike.
    internal var bodyText: String {
      String(decoding: raw, as: UTF8.self)
    }

    /// Best-effort JSON decode of `raw`; `nil` when the body isn't JSON.
    /// Computed (not stored) so the frame stays `Sendable` — `Any` isn't.
    internal var json: Any? {
      try? JSONSerialization.jsonObject(with: raw)
    }

    /// Whether the frame carries a payload worth inspecting. A long-poll that
    /// returns empty (a server-side keepalive / timeout) is not a delivery.
    internal var isEmpty: Bool {
      raw.isEmpty
    }

    /// The frame decoded into a typed ``CourierNotification``, or `nil` if the
    /// body isn't a recognizable notification (e.g. a keepalive).
    internal var notification: CourierNotification? {
      try? CourierNotification(data: raw)
    }

    internal init(statusCode: Int?, raw: Data) {
      self.statusCode = statusCode
      self.raw = raw
    }
  }
#endif

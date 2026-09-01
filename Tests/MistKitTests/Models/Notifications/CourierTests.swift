//
//  CourierTests.swift
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
  internal import Foundation
  internal import Testing

  @testable import MistKit

  @Suite("Courier")
  internal struct CourierTests {
    private static func courierURL() throws -> URL {
      try #require(URL(string: "https://webcourier.icloud.com/poll"))
    }

    @Test("pollOnce throws on a non-2xx status instead of looping silently")
    internal func pollOnceThrowsOnHTTPError() async throws {
      let url = try Self.courierURL()
      let transport: Courier.Transport = { _, _ in (statusCode: 401, data: Data()) }
      do {
        _ = try await Courier.pollOnce(courierURL: url, transport: transport)
        Issue.record("expected pollOnce to throw on a 401")
      } catch let error as CloudKitError {
        guard case .httpError(let statusCode) = error else {
          Issue.record("expected .httpError, got \(error)")
          return
        }
        #expect(statusCode == 401)
      }
    }

    @Test("pollOnce returns nil for an empty keepalive body")
    internal func pollOnceReturnsNilOnEmptyBody() async throws {
      let url = try Self.courierURL()
      let transport: Courier.Transport = { _, _ in (statusCode: 200, data: Data()) }
      let result = try await Courier.pollOnce(courierURL: url, transport: transport)
      #expect(result == nil)
    }

    @Test("pollOnce decodes a notification from a 2xx body")
    internal func pollOnceDecodesNotification() async throws {
      let url = try Self.courierURL()
      let body = #"{"ck":{"qry":{"fo":1,"sid":"s","rid":"r"}}}"#
      let transport: Courier.Transport = { _, _ in
        (statusCode: 200, data: Data(body.utf8))
      }
      let result = try await Courier.pollOnce(courierURL: url, transport: transport)
      let notification = try #require(result)
      #expect(notification.reason == .recordCreated)
    }
    @Test("notifications yields a decoded notification from the stream")
    internal func notificationsYieldsDecodedNotification() async throws {
      let url = try Self.courierURL()
      let body = #"{"ck":{"qry":{"fo":1,"sid":"s","rid":"r"}}}"#
      final class PollBox: @unchecked Sendable {
        var count = 0
      }
      let polls = PollBox()
      let transport: Courier.Transport = { _, _ in
        polls.count += 1
        if polls.count == 1 {
          return (statusCode: 200, data: Data(body.utf8))
        }
        try await Task.sleep(for: .seconds(30))
        return (statusCode: 200, data: Data())
      }

      let stream = Courier.notifications(courierURL: url, perPollTimeout: 1, transport: transport)
      let task = Task<CourierNotification?, Error> {
        for try await notification in stream {
          return notification
        }
        return nil
      }
      defer { task.cancel() }

      let notification = try await task.value
      let decoded = try #require(notification)
      #expect(decoded.reason == CourierNotification.Reason.recordCreated)
      #expect(polls.count >= 1)
    }
  }
#endif

//
//  URLSession+CourierPoll.swift
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

public import Foundation

#if canImport(FoundationNetworking)
  public import FoundationNetworking
#endif

#if !os(WASI)
  @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
  extension URLSession {
    /// Long-poll a CloudKit `webcourierURL` for a single response.
    ///
    /// Issues a GET bounded by `timeout` and returns the raw HTTP response
    /// without decoding. ``Courier`` decodes the body into a
    /// ``CourierNotification``. This is the default ``Courier/Transport``
    /// implementation.
    ///
    /// - Parameters:
    ///   - url: The `webcourierURL` to poll.
    ///   - timeout: How long the request waits before giving up.
    /// - Returns: Tuple containing the optional HTTP status code and body.
    /// - Throws: Error if the request fails.
    public func pollCourier(
      _ url: URL,
      timeout: TimeInterval
    ) async throws -> (statusCode: Int?, data: Data) {
      var request = URLRequest(url: url)
      request.httpMethod = "GET"
      request.timeoutInterval = timeout
      let (data, response) = try await self.data(for: request)
      let statusCode = (response as? HTTPURLResponse)?.statusCode
      return (statusCode, data)
    }
  }
#endif

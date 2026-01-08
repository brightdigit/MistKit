//
//  MockURLProtocol.swift
//  BushelCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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
  import FoundationNetworking
#endif

/// Mock URLProtocol for intercepting and simulating HTTP requests in tests
internal final class MockURLProtocol: URLProtocol, @unchecked Sendable {
  /// Request handler that returns a response and optional data for a given request
  nonisolated(unsafe) internal static var requestHandler:
    ((URLRequest) throws -> (HTTPURLResponse, Data?))?

  override internal class func canInit(with request: URLRequest) -> Bool {
    // Handle all requests
    true
  }

  override internal class func canonicalRequest(for request: URLRequest) -> URLRequest {
    // Return the request as-is
    request
  }

  override internal func startLoading() {
    guard let handler = Self.requestHandler else {
      fatalError("MockURLProtocol: Request handler not configured")
    }

    do {
      let (response, data) = try handler(request)
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      if let data = data {
        client?.urlProtocol(self, didLoad: data)
      }
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override internal func stopLoading() {
    // Nothing to clean up
  }
}

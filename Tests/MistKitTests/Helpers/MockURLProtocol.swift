//
//  MockURLProtocol.swift
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

  #if canImport(FoundationNetworking)
    internal import FoundationNetworking
  #endif

  /// Intercepts `URLSession` traffic in tests. Suites that use this type must
  /// be `.serialized` because the handler is process-global.
  internal final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) internal static var requestHandler:
      (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

    override internal class func canInit(with request: URLRequest) -> Bool {
      true
    }

    override internal class func canonicalRequest(for request: URLRequest) -> URLRequest {
      request
    }

    override internal func startLoading() {
      guard let handler = Self.requestHandler else {
        client?.urlProtocol(self, didFailWithError: URLError(.unknown))
        return
      }

      do {
        let (response, data) = try handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
      } catch {
        client?.urlProtocol(self, didFailWithError: error)
      }
    }

    override internal func stopLoading() {}

    /// Ephemeral session that routes every request through this protocol.
    internal static func makeSession() -> URLSession {
      let configuration = URLSessionConfiguration.ephemeral
      configuration.protocolClasses = [MockURLProtocol.self]
      configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
      return URLSession(configuration: configuration)
    }
  }
#endif

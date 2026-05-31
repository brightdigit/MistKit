//
//  LoggingMiddleware.swift
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

internal import Foundation
internal import HTTPTypes
internal import Logging
internal import OpenAPIRuntime

/// Logging middleware for HTTP request/response tracing.
///
/// Emits at `.debug` level — install a `LogHandler` and set
/// `logLevel = .debug` on `com.brightdigit.MistKit.middleware` to opt in.
internal struct LoggingMiddleware: ClientMiddleware {
  /// Maximum bytes of a response body collected at debug level.
  ///
  /// Sized to surface the JSON envelope and error reason without doubling
  /// the memory footprint of large CloudKit responses. Bodies bigger than
  /// this still stream through to the caller untouched.
  private static let responseBodyLogCap: Int = 64 * 1_024

  private let logger = Logger(subsystem: .middleware)

  internal func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    logRequest(request, baseURL: baseURL)
    let (response, responseBody) = try await next(request, body, baseURL)
    let finalResponseBody = await logResponse(response, body: responseBody)
    return (response, finalResponseBody)
  }

  private func logRequest(_ request: HTTPRequest, baseURL: URL) {
    let fullPath = baseURL.absoluteString + (request.path ?? "")
    logger.debug("🌐 CloudKit Request: \(request.method.rawValue) \(fullPath)")
    logger.debug("   Base URL: \(baseURL.absoluteString)")
    logger.debug("   Path: \(request.path ?? "none")")
    logger.debug("   Headers: \(request.headerFields)")

    logQueryParameters(for: request, baseURL: baseURL)
  }

  private func logQueryParameters(for request: HTTPRequest, baseURL: URL) {
    guard logger.logLevel <= .debug,
      let path = request.path,
      let url = URL(string: path, relativeTo: baseURL),
      let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
      let queryItems = components.queryItems
    else {
      return
    }

    logger.debug("   Query Parameters:")
    for item in queryItems {
      logger.debug("     \(item.name): \(item.value ?? "nil")")
    }
  }

  private func logResponse(_ response: HTTPResponse, body: HTTPBody?) async -> HTTPBody? {
    logger.debug("✅ CloudKit Response: \(response.status.code)")

    if response.status.code == 421 {
      logger.warning(
        "⚠️  421 Misdirected Request - The server cannot produce a response for this request"
      )
    }

    guard logger.logLevel <= .debug else {
      return body
    }

    #if !os(WASI)
      return await logResponseBody(body, contentType: response.headerFields[.contentType])
    #else
      return body
    #endif
  }

  #if !os(WASI)
    private func logResponseBody(
      _ responseBody: HTTPBody?,
      contentType: String?
    ) async -> HTTPBody? {
      guard let responseBody = responseBody else {
        return nil
      }

      // Only collect bodies we can actually render as text. Asset payloads
      // and other binary streams just inflate memory without producing a
      // useful log line.
      guard let contentType = contentType,
        contentType.lowercased().contains("application/json")
      else {
        logger.debug("📄 Response Body: <skipped, content-type=\(contentType ?? "unknown")>")
        return responseBody
      }

      do {
        let bodyData = try await Data(
          collecting: responseBody,
          upTo: Self.responseBodyLogCap
        )
        logBodyData(bodyData)
        return HTTPBody(bodyData)
      } catch {
        logger.error("📄 Response Body: <failed to read: \(error)>")
        return responseBody
      }
    }

    private func logBodyData(_ bodyData: Data) {
      if let jsonString = String(data: bodyData, encoding: .utf8) {
        logger.debug("📄 Response Body:")
        logger.debug("\(jsonString)")
      } else {
        logger.debug("📄 Response Body: <non-UTF8 data, \(bodyData.count) bytes>")
      }
    }
  #endif
}

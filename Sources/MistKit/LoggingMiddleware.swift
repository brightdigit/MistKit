//
//  LoggingMiddleware.swift
//  PackageDSLKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import Foundation
import HTTPTypes
import OpenAPIRuntime

/// Logging middleware for debugging
internal struct LoggingMiddleware: ClientMiddleware {
  internal func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    #if DEBUG
      logRequest(request, baseURL: baseURL)
    #endif

    let (response, responseBody) = try await next(request, body, baseURL)

    #if DEBUG
      let finalResponseBody = await logResponse(response, body: responseBody)
      return (response, finalResponseBody)
    #else
      return (response, responseBody)
    #endif
  }

  #if DEBUG
    /// Log outgoing request details
    private func logRequest(_ request: HTTPRequest, baseURL: URL) {
      let fullPath = baseURL.absoluteString + (request.path ?? "")
      print("🌐 CloudKit Request: \(request.method.rawValue) \(fullPath)")
      print("   Base URL: \(baseURL.absoluteString)")
      print("   Path: \(request.path ?? "none")")
      print("   Headers: \(request.headerFields)")

      logQueryParameters(for: request, baseURL: baseURL)
    }

    /// Log query parameters from request
    private func logQueryParameters(for request: HTTPRequest, baseURL: URL) {
      guard let path = request.path,
        let url = URL(string: path, relativeTo: baseURL),
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
        let queryItems = components.queryItems
      else {
        return
      }

      print("   Query Parameters:")
      for item in queryItems {
        let value = formatQueryValue(for: item)
        print("     \(item.name): \(value)")
      }
    }

    /// Format query parameter value for logging
    private func formatQueryValue(for item: URLQueryItem) -> String {
      guard let value = item.value else {
        return "nil"
      }

      // Mask sensitive query parameters
      let lowercasedName = item.name.lowercased()
      if lowercasedName.contains("token") || lowercasedName.contains("key")
        || lowercasedName.contains("secret") || lowercasedName.contains("auth")
      {
        return SecureLogging.maskToken(value)
      }

      return value
    }

    /// Log incoming response details
    private func logResponse(_ response: HTTPResponse, body: HTTPBody?) async -> HTTPBody? {
      print("✅ CloudKit Response: \(response.status.code)")

      if response.status.code == 421 {
        print("⚠️  421 Misdirected Request - The server cannot produce a response for this request")
      }

      return await logResponseBody(body)
    }

    /// Log response body content
    private func logResponseBody(_ responseBody: HTTPBody?) async -> HTTPBody? {
      guard let responseBody = responseBody else {
        return nil
      }

      do {
        let bodyData = try await Data(collecting: responseBody, upTo: 1_024 * 1_024)
        logBodyData(bodyData)
        return HTTPBody(bodyData)
      } catch {
        print("📄 Response Body: <failed to read: \(error)>")
        return responseBody
      }
    }

    /// Log the actual body data content
    private func logBodyData(_ bodyData: Data) {
      if let jsonString = String(data: bodyData, encoding: .utf8) {
        print("📄 Response Body:")
        print(SecureLogging.safeLogMessage(jsonString))
      } else {
        print("📄 Response Body: <non-UTF8 data, \(bodyData.count) bytes>")
      }
    }
  #endif
}

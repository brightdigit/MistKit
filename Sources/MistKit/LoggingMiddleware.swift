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

import Foundation
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
      let fullPath = baseURL.absoluteString + (request.path ?? "")
      print("🌐 CloudKit Request: \(request.method.rawValue) \(fullPath)")
      print("   Base URL: \(baseURL.absoluteString)")
      print("   Path: \(request.path ?? "none")")
      print("   Headers: \(request.headerFields)")

      // Log query parameters for debugging authentication
      if let path = request.path, let url = URL(string: path, relativeTo: baseURL) {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
          if let queryItems = components.queryItems {
            print("   Query Parameters:")
            for item in queryItems {
              if item.name == "ckWebAuthToken" {
                print("     \(item.name): \(item.value?.prefix(20) ?? "nil")... (encoded)")
              } else {
                print("     \(item.name): \(item.value ?? "nil")")
              }
            }
          }
        }
      }
    #endif

    let (response, responseBody) = try await next(request, body, baseURL)

    #if DEBUG
      print("✅ CloudKit Response: \(response.status.code)")
      if response.status.code == 421 {
        print("⚠️  421 Misdirected Request - The server cannot produce a response for this request")
      }

      // Log response body for debugging without consuming the original stream
      let finalResponseBody: HTTPBody?
      if let responseBody = responseBody {
        do {
          // Buffer the response data
          let bodyData = try await Data(collecting: responseBody, upTo: 1_024 * 1_024)  // 1MB limit

          // Log the data
          if let jsonString = String(data: bodyData, encoding: .utf8) {
            print("📄 Response Body:")
            print(jsonString)
          } else {
            print("📄 Response Body: <non-UTF8 data, \(bodyData.count) bytes>")
          }

          // Create a new HTTPBody from the buffered data for the parser
          finalResponseBody = HTTPBody(bodyData)
        } catch {
          print("📄 Response Body: <failed to read: \(error)>")
          finalResponseBody = responseBody  // fallback to original if buffering fails
        }
      } else {
        finalResponseBody = responseBody
      }
    #endif

    return (response, finalResponseBody)
  }
}

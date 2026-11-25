//
//  CloudKitManagementServiceTests+ErrorBodies.swift
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
internal import Testing

@testable import MistKit

extension CloudKitManagementServiceTests {
  /// Error responses the generated client can't decode as a `RequestError`,
  /// and streamed (single-read) error bodies.
  @Suite("Error bodies")
  internal struct ErrorBodies {
    @Test("The HTTP status wins over the body's code")
    internal func statusWinsOverCode() async throws {
      let (service, _) = makeService(
        response: RecordedManagementFixtures.jsonResponse(
          #"{"code": 401, "message": "invalid-or-expired-session", "reason": "r"}"#,
          statusCode: 403
        )
      )
      let error = await exportTextError(service)
      guard case .requestFailed(let failure) = error as? CloudKitManagementError else {
        Issue.record("Expected requestFailed, got \(String(describing: error))")
        return
      }
      #expect(failure.statusCode == 403)
      #expect(failure.code == 401)
    }

    @Test("A JSON body missing a required key becomes httpError with the body text")
    internal func incompleteRequestError() async throws {
      let json = #"{"code": 500, "message": "INTERNAL_ERROR"}"#
      let (service, _) = makeService(
        response: RecordedManagementFixtures.jsonResponse(json, statusCode: 500)
      )
      let error = await exportTextError(service)
      guard case .httpError(let statusCode, let body) = error as? CloudKitManagementError else {
        Issue.record("Expected httpError, got \(String(describing: error))")
        return
      }
      #expect(statusCode == 500)
      #expect(body == json)
    }

    @Test("An error with no body becomes httpError with a nil body")
    internal func emptyErrorBody() async throws {
      let (service, _) = makeService(response: ResponseConfig(statusCode: 503))
      let error = await exportTextError(service)
      guard case .httpError(let statusCode, let body) = error as? CloudKitManagementError else {
        Issue.record("Expected httpError, got \(String(describing: error))")
        return
      }
      #expect(statusCode == 503)
      #expect(body == nil)
    }

    @Test("An error body that isn't UTF-8 becomes httpError with a nil body")
    internal func binaryErrorBody() async throws {
      var headers = HTTPFields()
      headers[.contentType] = "application/octet-stream"
      let (service, _) = makeService(
        response: ResponseConfig(statusCode: 500, headers: headers, body: Data([0xFF, 0xFE]))
      )
      let error = await exportTextError(service)
      guard case .httpError(500, let body) = error as? CloudKitManagementError else {
        Issue.record("Expected httpError 500, got \(String(describing: error))")
        return
      }
      #expect(body == nil)
    }

    @Test("A streamed non-JSON error body is still read back into httpError")
    internal func streamedErrorBody() async throws {
      var headers = HTTPFields()
      headers[.contentType] = "text/html"
      let service = makeService(
        transport: StreamingTransport(
          statusCode: 502,
          headers: headers,
          chunks: [Data("<h1>Bad ".utf8), Data("Gateway</h1>".utf8)]
        )
      )
      let error = await exportTextError(service)
      guard case .httpError(502, let body) = error as? CloudKitManagementError else {
        Issue.record("Expected httpError 502, got \(String(describing: error))")
        return
      }
      #expect(body == "<h1>Bad Gateway</h1>")
    }

    @Test("A streamed RequestError decodes into requestFailed")
    internal func streamedRequestError() async throws {
      var headers = HTTPFields()
      headers[.contentType] = "application/json"
      let service = makeService(
        transport: StreamingTransport(
          statusCode: 401,
          headers: headers,
          chunks: [Data(RecordedManagementFixtures.invalidTokenErrorJSON.utf8)]
        )
      )
      let error = await exportTextError(service)
      guard case .requestFailed(let failure) = error as? CloudKitManagementError else {
        Issue.record("Expected requestFailed, got \(String(describing: error))")
        return
      }
      #expect(failure.message == "invalid-or-expired-session")
    }
  }
}

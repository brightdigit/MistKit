//
//  CloudKitManagementServiceTests+Errors.swift
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
  @Suite("Errors")
  internal struct Errors {
    @Test("A JSON RequestError body becomes requestFailed with every field")
    internal func requestError() async throws {
      let (service, _) = makeService(
        response: ProvisionalManagementFixtures.jsonResponse(
          ProvisionalManagementFixtures.requestErrorJSON,
          statusCode: 401
        )
      )
      await #expect {
        _ = try await service.exportSchemaText(environment: .development)
      } throws: { error in
        guard case .requestFailed(let failure) = error as? CloudKitManagementError else {
          return false
        }
        return failure
          == ManagementRequestFailure(
            statusCode: 401,
            code: 401,
            message: "AUTHENTICATION_FAILED",
            reason: "Management token is invalid or expired",
            detailedMessage: "Generate a new token in CloudKit Console",
            requestUUID: "6E1D9A6B-0000-4000-8000-000000000001",
            retryAfterSeconds: 30
          )
      }
    }

    @Test("A RequestError with only the required keys decodes")
    internal func minimalRequestError() async throws {
      let (service, _) = makeService(
        response: ProvisionalManagementFixtures.jsonResponse(
          #"{"code": 404, "message": "NOT_FOUND", "reason": "Unknown container"}"#,
          statusCode: 404
        )
      )
      await #expect {
        _ = try await service.exportSchemaText(environment: .development)
      } throws: { error in
        guard case .requestFailed(let failure) = error as? CloudKitManagementError else {
          return false
        }
        return failure.statusCode == 404 && failure.message == "NOT_FOUND"
          && failure.reason == "Unknown container" && failure.detailedMessage == nil
          && failure.requestUUID == nil && failure.retryAfterSeconds == nil
      }
    }

    @Test("A non-JSON error body becomes httpError carrying the body text")
    internal func plainError() async throws {
      let (service, _) = makeService(
        response: ProvisionalManagementFixtures.textResponse("Bad Gateway", statusCode: 502)
      )
      await #expect {
        _ = try await service.exportSchemaText(environment: .development)
      } throws: { error in
        guard case .httpError(let statusCode, let body) = error as? CloudKitManagementError
        else {
          return false
        }
        return statusCode == 502 && body == "Bad Gateway"
      }
    }

    @Test("A transport error propagates unchanged")
    internal func transportError() async throws {
      let (service, _) = makeService(response: .timeout())
      await #expect(throws: URLError.self) {
        _ = try await service.exportSchemaText(environment: .development)
      }
    }

    @Test("Errors describe themselves without the token")
    internal func descriptions() {
      let failure = ManagementRequestFailure(
        statusCode: 401,
        code: 401,
        message: "AUTHENTICATION_FAILED",
        reason: "Management token is invalid or expired",
        detailedMessage: nil,
        requestUUID: nil,
        retryAfterSeconds: nil
      )
      #expect(
        CloudKitManagementError.requestFailed(failure).errorDescription
          == "CloudKit Management API error 401 AUTHENTICATION_FAILED: "
          + "Management token is invalid or expired"
      )
      #expect(
        CloudKitManagementError.httpError(statusCode: 502, body: "Bad Gateway").errorDescription
          == "CloudKit Management API HTTP 502"
      )
    }
  }
}

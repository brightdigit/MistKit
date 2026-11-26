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
    private static func parseError(of text: String) -> SchemaParseError? {
      do {
        _ = try CloudKitSchema(parsing: text)
        return nil
      } catch {
        return error as? SchemaParseError
      }
    }

    @Test(
      "Each recorded RequestError becomes requestFailed with its fields",
      arguments: [
        (
          RecordedManagementFixtures.invalidTokenErrorJSON, 401,
          "invalid-or-expired-session", "Failed to validate management token"
        ),
        (
          RecordedManagementFixtures.missingTokenErrorJSON, 401,
          "authentication-failed", "There was a problem with your request."
        ),
        (
          RecordedManagementFixtures.unknownContainerErrorJSON, 403,
          "authorization-failed",
          "User doesn't have access to container or container does not exist"
        ),
        (
          RecordedManagementFixtures.badRequestErrorJSON, 400,
          "Request unparseable or not as per supported schema",
          "There was a problem with your request."
        ),
      ]
    )
    internal func recordedRequestErrors(
      json: String,
      statusCode: Int,
      message: String,
      reason: String
    ) async throws {
      let (service, _) = makeService(
        response: RecordedManagementFixtures.jsonResponse(json, statusCode: statusCode)
      )
      let error = await exportTextError(service)
      guard case .requestFailed(let failure) = error as? CloudKitManagementError else {
        Issue.record("Expected requestFailed, got \(String(describing: error))")
        return
      }
      #expect(failure.statusCode == statusCode)
      #expect(failure.code == statusCode)
      #expect(failure.message == message)
      #expect(failure.reason == reason)
      #expect(failure.requestUUID?.hasPrefix("00000000-0000-4000-8000-") == true)
      #expect(failure.detailedMessage == nil)
      #expect(failure.retryAfterSeconds == nil)
    }

    @Test("A RequestError with every optional key decodes them all")
    internal func fullRequestError() async throws {
      let (service, _) = makeService(
        response: RecordedManagementFixtures.jsonResponse(
          RecordedManagementFixtures.fullRequestErrorJSON,
          statusCode: 503
        )
      )
      let error = await exportTextError(service)
      guard case .requestFailed(let failure) = error as? CloudKitManagementError else {
        Issue.record("Expected requestFailed, got \(String(describing: error))")
        return
      }
      #expect(
        failure
          == ManagementRequestFailure(
            statusCode: 503,
            code: 503,
            message: "service-unavailable",
            reason: "Try again later",
            detailedMessage: "The service is temporarily unavailable",
            requestUUID: "00000000-0000-4000-8000-000000000009",
            retryAfterSeconds: 30
          )
      )
    }

    @Test("A non-JSON error body becomes httpError carrying the body text")
    internal func plainError() async throws {
      let (service, _) = makeService(
        response: RecordedManagementFixtures.textResponse("Bad Gateway", statusCode: 502)
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
    internal func descriptions() throws {
      let failure = ManagementRequestFailure(
        statusCode: 401,
        code: 401,
        message: "invalid-or-expired-session",
        reason: "Failed to validate management token",
        detailedMessage: nil,
        requestUUID: nil,
        retryAfterSeconds: nil
      )
      #expect(
        CloudKitManagementError.requestFailed(failure).errorDescription
          == "CloudKit Management API error 401 invalid-or-expired-session: "
          + "Failed to validate management token"
      )
      #expect(
        CloudKitManagementError.httpError(statusCode: 502, body: "Bad Gateway").errorDescription
          == "CloudKit Management API HTTP 502"
      )
      #expect(
        CloudKitManagementError.invalidResponse(reason: "schema export body is not UTF-8")
          .errorDescription
          == "CloudKit Management API returned an unusable response: "
          + "schema export body is not UTF-8"
      )
      let parseError = try #require(Self.parseError(of: "not a schema"))
      let description = CloudKitManagementError.invalidSchema(parseError, text: "not a schema")
        .errorDescription
      #expect(
        description?.hasPrefix("CloudKit Management API returned a schema MistKit couldn't parse.")
          == true
      )
    }
  }
}

//
//  CloudKitServiceTests.ServerErrorCodes+RetryHints.swift
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

extension CloudKitServiceTests.ServerErrorCodes {
  /// `retryAfter` and `redirectURL` on a request-level failure body, and the
  /// public ``CloudKitError`` accessors built on them (MistKit #489, #491, #496).
  @Suite("Retry hints")
  internal struct RetryHints {
    private static func service(statusCode: Int, json: String) throws -> CloudKitService {
      var headers = HTTPFields()
      headers[.contentType] = "application/json"
      let provider = ResponseProvider(
        defaultResponse: ResponseConfig(
          statusCode: statusCode,
          headers: headers,
          body: Data(json.utf8)
        )
      )
      return try CloudKitService(
        containerIdentifier: TestConstants.serviceContainerIdentifier,
        credentials: Credentials(apiAuth: APICredentials(apiToken: TestConstants.apiToken)),
        transport: MockTransport(responseProvider: provider)
      )
    }

    private static func queryError(_ service: CloudKitService) async -> CloudKitError? {
      do {
        _ = try await service.queryRecords(
          Query(recordType: "Note"),
          database: .public(.prefers(.serverToServer))
        )
        return nil
      } catch {
        return error
      }
    }

    @Test("THROTTLED keeps the body's retryAfter and is retryable")
    internal func throttledRetryAfter() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let service = try Self.service(
        statusCode: 429,
        json: #"{"serverErrorCode":"THROTTLED","reason":"slow down","retryAfter":12}"#
      )
      let error = try #require(await Self.queryError(service))
      guard case .throttled(let reason, let retryAfter) = error else {
        Issue.record("expected .throttled, got \(error)")
        return
      }
      #expect(reason == "slow down")
      #expect(retryAfter == 12)
      #expect(error.retryAfter == 12)
      #expect(error.reason == "slow down")
      #expect(error.isRetryable)
    }

    @Test("TRY_AGAIN_LATER without retryAfter is retryable with no wait")
    internal func tryAgainLaterWithoutRetryAfter() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let service = try Self.service(
        statusCode: 503,
        json: #"{"serverErrorCode":"TRY_AGAIN_LATER","reason":"unavailable"}"#
      )
      let error = try #require(await Self.queryError(service))
      guard case .tryAgainLater(_, nil) = error else {
        Issue.record("expected .tryAgainLater with no retryAfter, got \(error)")
        return
      }
      #expect(error.isRetryable)
      #expect(error.retryAfter == nil)
    }

    @Test("AUTHENTICATION_REQUIRED keeps the body's redirectURL")
    internal func authenticationRequiredRedirect() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let service = try Self.service(
        statusCode: 421,
        json: #"{"serverErrorCode":"AUTHENTICATION_REQUIRED","reason":"sign in","#
          + #""redirectURL":"https://idmsa.apple.com/signin"}"#
      )
      let error = try #require(await Self.queryError(service))
      guard case .authenticationRequired(_, let redirectURL) = error else {
        Issue.record("expected .authenticationRequired, got \(error)")
        return
      }
      #expect(redirectURL == "https://idmsa.apple.com/signin")
      #expect(error.redirectURL == "https://idmsa.apple.com/signin")
      #expect(!error.isRetryable)
    }

    @Test("fetchWebAuthSignInURL returns the AUTHENTICATION_REQUIRED redirectURL")
    internal func signInURL() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let service = try Self.service(
        statusCode: 421,
        json: #"{"serverErrorCode":"AUTHENTICATION_REQUIRED","#
          + #""redirectURL":"https://idmsa.apple.com/signin"}"#
      )
      let url = try await service.fetchWebAuthSignInURL()
      #expect(url.absoluteString == "https://idmsa.apple.com/signin")
    }

    @Test("fetchWebAuthSignInURL throws incompleteResponse without a redirectURL")
    internal func signInURLMissing() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let service = try Self.service(
        statusCode: 421,
        json: #"{"serverErrorCode":"AUTHENTICATION_REQUIRED"}"#
      )
      do {
        _ = try await service.fetchWebAuthSignInURL()
        Issue.record("expected fetchWebAuthSignInURL to throw")
      } catch {
        guard case .incompleteResponse = error else {
          Issue.record("expected .incompleteResponse, got \(error)")
          return
        }
      }
    }

    @Test("reason, retryAfter and isRetryable read per-record failures")
    internal func perRecordFailure() {
      let failure = RecordOperationFailure(
        identifier: "note-1",
        serverErrorCode: .tryAgainLater,
        reason: "busy",
        retryAfter: 3
      )
      let error = CloudKitError.recordOperationFailed(failure)
      #expect(error.reason == "busy")
      #expect(error.retryAfter == 3)
      #expect(error.isRetryable)
      let conflict = CloudKitError.recordOperationFailed(
        RecordOperationFailure(identifier: "note-1", serverErrorCode: .conflict)
      )
      #expect(!conflict.isRetryable)
    }

    @Test("only THROTTLED and TRY_AGAIN_LATER are retryable")
    internal func retryableClassification() {
      #expect(!CloudKitError.badRequest(reason: nil).isRetryable)
      #expect(!CloudKitError.internalServerError(reason: "x").isRetryable)
      #expect(!CloudKitError.networkError(URLError(.timedOut)).isRetryable)
      #expect(!CloudKitError.authenticationRequired(reason: nil).isRetryable)
      #expect(CloudKitError.throttled(reason: nil).isRetryable)
      #expect(CloudKitError.tryAgainLater(reason: nil, retryAfter: 5).isRetryable)
    }

    @Test("reason covers server codes and bodies without a code")
    internal func reasonAccessor() {
      #expect(CloudKitError.zoneNotFound(reason: "gone").reason == "gone")
      #expect(
        CloudKitError.unknownServerError(code: "NEW", statusCode: 400, reason: "r").reason
          == "r"
      )
      #expect(CloudKitError.httpErrorWithDetails(statusCode: 400, reason: "d").reason == "d")
      #expect(CloudKitError.invalidResponse.reason == nil)
    }
  }
}

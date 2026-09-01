//
//  CloudKitResponseTypeTests.swift
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
internal import MistKitOpenAPI
internal import OpenAPIRuntime
internal import Testing

@testable import MistKit

@Suite("CloudKit Response Mapping")
internal struct CloudKitResponseTypeTests {
  private typealias ServerCode = Components.Schemas.ErrorResponse.serverErrorCodePayload

  private static func undocumentedPayload() -> UndocumentedPayload {
    UndocumentedPayload(body: HTTPBody(Data()))
  }

  private static func sampleFailure(
    code: ServerCode = .BAD_REQUEST,
    reason: String = "failure"
  ) -> Components.Responses.Failure {
    Components.Responses.Failure(
      body: .json(
        .init(
          serverErrorCode: code,
          reason: reason
        )
      )
    )
  }

  private static func assertMapsToStatusCode<T: CloudKitResponseType>(
    _ output: T,
    statusCode: Int
  ) {
    guard let mapped = output.toCloudKitError() else {
      Issue.record("expected non-nil CloudKitError for HTTP \(statusCode)")
      return
    }
    #expect(mapped.httpStatusCode == statusCode)
  }

  @Test("listZones maps documented HTTP failures")
  internal func listZonesMapsFailures() {
    let mappings: [(() -> Operations.listZones.Output, Int)] = [
      ({ .badRequest(Self.sampleFailure(code: .BAD_REQUEST)) }, 400),
      ({ .unauthorized(Self.sampleFailure(code: .AUTHENTICATION_FAILED)) }, 401),
      ({ .forbidden(Self.sampleFailure(code: .ACCESS_DENIED)) }, 403),
      ({ .notFound(Self.sampleFailure(code: .NOT_FOUND)) }, 404),
      ({ .conflict(Self.sampleFailure(code: .CONFLICT)) }, 409),
      (
        {
          .preconditionFailed(Self.sampleFailure(code: .VALIDATING_REFERENCE_ERROR))
        }, 412
      ),
      ({ .contentTooLarge(Self.sampleFailure(code: .QUOTA_EXCEEDED)) }, 413),
      (
        {
          .misdirectedRequest(Self.sampleFailure(code: .AUTHENTICATION_REQUIRED))
        }, 421
      ),
      ({ .tooManyRequests(Self.sampleFailure(code: .THROTTLED)) }, 429),
      ({ .internalServerError(Self.sampleFailure(code: .INTERNAL_ERROR)) }, 500),
      ({ .serviceUnavailable(Self.sampleFailure(code: .TRY_AGAIN_LATER)) }, 503),
      ({ .undocumented(statusCode: 418, Self.undocumentedPayload()) }, 418),
    ]
    for (makeOutput, statusCode) in mappings {
      Self.assertMapsToStatusCode(makeOutput(), statusCode: statusCode)
    }
  }

  @Test("lookupZones maps documented HTTP failures")
  internal func lookupZonesMapsFailures() {
    Self.assertMapsToStatusCode(
      Operations.lookupZones.Output.badRequest(Self.sampleFailure(code: .BAD_REQUEST)),
      statusCode: 400
    )
    Self.assertMapsToStatusCode(
      Operations.lookupZones.Output.unauthorized(Self.sampleFailure(code: .AUTHENTICATION_FAILED)),
      statusCode: 401
    )
    Self.assertMapsToStatusCode(
      Operations.lookupZones.Output.undocumented(statusCode: 418, Self.undocumentedPayload()),
      statusCode: 418
    )
  }

  @Test("modifyZones maps documented HTTP failures")
  internal func modifyZonesMapsFailures() {
    Self.assertMapsToStatusCode(
      Operations.modifyZones.Output.badRequest(Self.sampleFailure(code: .BAD_REQUEST)),
      statusCode: 400
    )
    Self.assertMapsToStatusCode(
      Operations.modifyZones.Output.unauthorized(Self.sampleFailure(code: .AUTHENTICATION_FAILED)),
      statusCode: 401
    )
    Self.assertMapsToStatusCode(
      Operations.modifyZones.Output.undocumented(statusCode: 418, Self.undocumentedPayload()),
      statusCode: 418
    )
  }

  @Test("subscription list/lookup/modify outputs map HTTP failures")
  internal func subscriptionOutputsMapFailures() {
    Self.assertMapsToStatusCode(
      Operations.listSubscriptions.Output.unauthorized(
        Self.sampleFailure(code: .AUTHENTICATION_FAILED)
      ),
      statusCode: 401
    )
    Self.assertMapsToStatusCode(
      Operations.lookupSubscriptions.Output.badRequest(Self.sampleFailure(code: .BAD_REQUEST)),
      statusCode: 400
    )
    Self.assertMapsToStatusCode(
      Operations.modifySubscriptions.Output.badRequest(Self.sampleFailure(code: .BAD_REQUEST)),
      statusCode: 400
    )
  }

  @Test("fetchRecordChanges maps documented HTTP failures")
  internal func fetchRecordChangesMapsFailures() {
    Self.assertMapsToStatusCode(
      Operations.fetchRecordChanges.Output.tooManyRequests(Self.sampleFailure(code: .THROTTLED)),
      statusCode: 429
    )
    Self.assertMapsToStatusCode(
      Operations.fetchRecordChanges.Output.undocumented(
        statusCode: 418,
        Self.undocumentedPayload()
      ),
      statusCode: 418
    )
  }
}

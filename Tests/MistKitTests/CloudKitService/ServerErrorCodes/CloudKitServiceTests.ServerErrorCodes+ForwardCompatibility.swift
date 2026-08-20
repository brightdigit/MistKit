//
//  CloudKitServiceTests.ServerErrorCodes+ForwardCompatibility.swift
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

internal import Testing

@testable import MistKit

extension CloudKitServiceTests.ServerErrorCodes {
  @Suite("Forward compatibility")
  internal struct ForwardCompatibility {
    /// A code Apple has not shipped — stands in for a future spec revision.
    private static let futureCode = "SOME_FUTURE_CODE"

    @Test("An unmodelled serverErrorCode maps to .unknownServerError")
    internal func unmodelledCodeMapsToUnknownServerError() throws {
      let error = CloudKitError(
        serverErrorCode: Self.futureCode,
        statusCode: 418,
        reason: "brand new failure"
      )

      guard case .unknownServerError(let code, let statusCode, let reason) = error else {
        Issue.record("expected .unknownServerError, got \(error)")
        return
      }
      #expect(code == Self.futureCode)
      #expect(statusCode == 418)
      #expect(reason == "brand new failure")
      #expect(error.serverErrorCode == Self.futureCode)
      #expect(error.httpStatusCode == 418)

      let description = try #require(error.errorDescription)
      #expect(description.contains(Self.futureCode))
      #expect(description.contains("418"))
      #expect(description.contains("brand new failure"))
    }

    @Test("A failure body with no serverErrorCode keeps its reason in .httpErrorWithDetails")
    internal func missingCodeMapsToHTTPErrorWithDetails() throws {
      let error = CloudKitError(
        serverErrorCode: nil,
        statusCode: 500,
        reason: "no code supplied"
      )

      guard case .httpErrorWithDetails(let statusCode, let reason) = error else {
        Issue.record("expected .httpErrorWithDetails, got \(error)")
        return
      }
      #expect(statusCode == 500)
      #expect(reason == "no code supplied")
      #expect(error.serverErrorCode == nil)

      let description = try #require(error.errorDescription)
      #expect(description.contains("500"))
      #expect(description.contains("no code supplied"))
    }

    /// Documents the *current* end-to-end behavior for a code MistKit does not
    /// model, which stops one layer short of `.unknownServerError`.
    ///
    /// `ErrorResponse.serverErrorCode` is a closed `enum` in `openapi.yaml`, so
    /// swift-openapi-generator emits a closed Swift enum and an unrecognized
    /// string fails to decode — the failure surfaces as `.decodingError` before
    /// MistKit's mapping ever runs. The guarantee that matters here is the
    /// negative one: an unmodelled code is never silently mistaken for a
    /// modelled case. `.unknownServerError` is the seam that takes over the
    /// moment the spec stops closing that enum; it is covered directly above.
    @Test("An unmodelled serverErrorCode on the wire never matches a modelled case")
    internal func unmodelledCodeOverTheWire() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.ServerErrorCodes.makeService(
        statusCode: 500,
        serverErrorCode: Self.futureCode,
        reason: "brand new failure"
      )

      do {
        _ = try await service.queryRecords(
          Query(recordType: "Note"),
          database: .public(.prefers(.serverToServer))
        )
        Issue.record("expected queryRecords to throw")
      } catch let error as CloudKitError {
        #expect(
          error.serverErrorCode == nil,
          "an unmodelled code must not be mistaken for a modelled one"
        )
        guard case .decodingError = error else {
          Issue.record(
            "expected .decodingError while the generated enum stays closed, got \(error)"
          )
          return
        }
      }
    }
  }
}

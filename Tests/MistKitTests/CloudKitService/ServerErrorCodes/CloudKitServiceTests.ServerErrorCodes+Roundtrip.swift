//
//  CloudKitServiceTests.ServerErrorCodes+Roundtrip.swift
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
  @Suite("Roundtrip")
  internal struct Roundtrip {
    @Test(
      "Each documented serverErrorCode surfaces as its dedicated case",
      arguments: CloudKitServiceTests.ServerErrorCodes.expectations
    )
    internal func documentedCodeMapsToDedicatedCase(
      _ expectation: CloudKitServiceTests.ServerErrorCodes.Expectation
    ) async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let reason = "reason for \(expectation.code)"
      let service = try CloudKitServiceTests.ServerErrorCodes.makeService(
        statusCode: expectation.statusCode,
        serverErrorCode: expectation.code,
        reason: reason
      )

      do {
        _ = try await service.queryRecords(
          Query(recordType: "Note"),
          database: .public(.prefers(.serverToServer))
        )
        Issue.record("expected queryRecords to throw for \(expectation.code)")
      } catch let error as CloudKitError {
        #expect(
          CloudKitServiceTests.ServerErrorCodes.caseLabel(of: error) == expectation.caseLabel
        )
        #expect(error.serverErrorCode == expectation.code)
        #expect(error.httpStatusCode == expectation.statusCode)
        let description = try #require(error.errorDescription)
        #expect(description.contains(expectation.code))
        #expect(description.contains(reason))
      }
    }
  }
}

//
//  DemoErrorsRunnerOutputTests.swift
//  MistDemoTests
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

import Foundation
import MistKit
import Testing

@testable import MistDemoKit

@Suite("DemoErrorsRunner Output")
internal struct DemoErrorsRunnerOutputTests {
  @Test("describe(_:) returns the tag when non-empty")
  internal func describeReturnsTag() async throws {
    let runner = try await DemoErrorsRunner(config: MistDemoConfig())

    #expect(runner.describe("ck-tag-1") == "ck-tag-1")
  }

  @Test("describe(_:) returns <none> for nil and empty inputs")
  internal func describeFallsBackToNone() async throws {
    let runner = try await DemoErrorsRunner(config: MistDemoConfig())

    #expect(runner.describe(nil) == "<none>")
    #expect(runner.describe("") == "<none>")
  }

  @Test("printRunnerHeader does not throw")
  internal func headerDoesNotThrow() async throws {
    let runner = try await DemoErrorsRunner(config: MistDemoConfig())
    runner.printRunnerHeader()
  }

  @Test("printRunnerFooter does not throw")
  internal func footerDoesNotThrow() async throws {
    let runner = try await DemoErrorsRunner(config: MistDemoConfig())
    runner.printRunnerFooter()
  }

  @Test("printSectionHeader does not throw and accepts arbitrary titles")
  internal func sectionHeaderDoesNotThrow() async throws {
    let runner = try await DemoErrorsRunner(config: MistDemoConfig())
    runner.printSectionHeader("section title")
    runner.printSectionHeader("")
  }

  @Test("printCloudKitError formats httpError with status code")
  internal func formatsHTTPError() async throws {
    let runner = try await DemoErrorsRunner(config: MistDemoConfig())
    let error = CloudKitError.httpError(statusCode: 404)
    runner.printCloudKitError(error, expectedStatus: 404)
    runner.printCloudKitError(error, expectedStatus: 401)
  }

  @Test("printCloudKitError formats httpErrorWithDetails with optional fields")
  internal func formatsHTTPErrorWithDetails() async throws {
    let runner = try await DemoErrorsRunner(config: MistDemoConfig())
    let withDetails = CloudKitError.httpErrorWithDetails(
      statusCode: 409,
      serverErrorCode: "CONFLICT",
      reason: "stale recordChangeTag"
    )
    runner.printCloudKitError(withDetails, expectedStatus: 409)

    let nilDetails = CloudKitError.httpErrorWithDetails(
      statusCode: 401,
      serverErrorCode: nil,
      reason: nil
    )
    runner.printCloudKitError(nilDetails, expectedStatus: 401)
  }

  @Test("printCloudKitError handles cases without an http status")
  internal func formatsErrorWithoutStatus() async throws {
    let runner = try await DemoErrorsRunner(config: MistDemoConfig())
    let error = CloudKitError.invalidResponse
    runner.printCloudKitError(error, expectedStatus: 500)
  }
}

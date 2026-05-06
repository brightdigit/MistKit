//
//  DeleteCommandTests.swift
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

// swiftlint:disable file_types_order one_declaration_per_file
@Suite("DeleteCommand Tests")
internal struct DeleteCommandTests {
  @Test("Command has correct static properties")
  internal func staticProperties() {
    #expect(DeleteCommand.commandName == "delete")
    #expect(DeleteCommand.abstract == "Delete an existing record from CloudKit")
    #expect(DeleteCommand.helpText.contains("DELETE"))
  }

  @Test("Command initializes with config")
  internal func initializesWithConfig() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = DeleteConfig(base: baseConfig, recordName: "rec-1")
    _ = DeleteCommand(config: config)
  }
}

@Suite("DeleteCommand.mapConflict Tests")
internal struct DeleteCommandMapConflictTests {
  @Test("Maps httpError 409 to .conflict with nil reason")
  internal func httpError409() {
    let result = DeleteCommand.mapConflict(.httpError(statusCode: 409))
    guard case .conflict(let reason) = result else {
      Issue.record("Expected .conflict, got \(String(describing: result))")
      return
    }
    #expect(reason == nil)
  }

  @Test("Maps httpErrorWithDetails 409 to .conflict including the reason")
  internal func httpErrorWithDetails409() {
    let result = DeleteCommand.mapConflict(
      .httpErrorWithDetails(
        statusCode: 409, serverErrorCode: "ATOMIC_ERROR", reason: "Change tag mismatch"
      )
    )
    guard case .conflict(let reason) = result else {
      Issue.record("Expected .conflict, got \(String(describing: result))")
      return
    }
    #expect(reason == "Change tag mismatch")
  }

  @Test("Maps httpErrorWithRawResponse 409 to .conflict with nil reason")
  internal func httpErrorWithRawResponse409() {
    let result = DeleteCommand.mapConflict(
      .httpErrorWithRawResponse(statusCode: 409, rawResponse: "...")
    )
    guard case .conflict(let reason) = result else {
      Issue.record("Expected .conflict, got \(String(describing: result))")
      return
    }
    #expect(reason == nil)
  }

  @Test(
    "Non-409 HTTP errors do not map to .conflict",
    arguments: [400, 401, 403, 404, 500, 503]
  )
  internal func nonConflictHTTPCodes(statusCode: Int) {
    #expect(DeleteCommand.mapConflict(.httpError(statusCode: statusCode)) == nil)
  }

  @Test("Non-HTTP CloudKitErrors do not map to .conflict")
  internal func nonHTTPErrors() {
    #expect(DeleteCommand.mapConflict(.invalidResponse) == nil)
  }
}

// swiftlint:enable file_types_order one_declaration_per_file

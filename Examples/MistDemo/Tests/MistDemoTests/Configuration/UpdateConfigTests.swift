//
//  UpdateConfigTests.swift
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
import Testing

@testable import MistDemoKit

@Suite("UpdateConfig")
internal enum UpdateConfigTests {}

@Suite("UpdateError")
struct UpdateErrorTests {
  @Test("conflict with nil reason produces a generic conflict description")
  func conflictNilReason() {
    let error = UpdateError.conflict(reason: nil)
    let description = error.errorDescription ?? ""

    #expect(description.contains("conflict"))
  }

  @Test("conflict with reason includes the reason in the description")
  func conflictWithReason() {
    let error = UpdateError.conflict(reason: "ATOMIC_ERROR")
    let description = error.errorDescription ?? ""

    #expect(description.contains("ATOMIC_ERROR"))
  }

  @Test("conflict suggests --force as a remedy")
  func conflictRecoveryMentionsForce() {
    let error = UpdateError.conflict(reason: nil)
    let suggestion = error.recoverySuggestion ?? ""

    #expect(suggestion.contains("--force"))
  }

  @Test("recordNameRequired has a description")
  func recordNameRequiredDescription() {
    let error = UpdateError.recordNameRequired
    #expect(error.errorDescription != nil)
  }

  @Test("noFieldsProvided has a description")
  func noFieldsProvidedDescription() {
    let error = UpdateError.noFieldsProvided
    #expect(error.errorDescription != nil)
  }
}

//
//  DeleteErrorTests.swift
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

import Testing

@testable import MistDemoKit

@Suite("DeleteError Tests")
internal struct DeleteErrorTests {
  @Test("recordNameRequired has a description")
  internal func recordNameRequiredDescription() {
    let error = DeleteError.recordNameRequired
    #expect(error.errorDescription != nil)
  }

  @Test("conflict description includes the reason when present")
  internal func conflictWithReason() {
    let error = DeleteError.conflict(reason: "ATOMIC_ERROR")
    #expect(error.errorDescription?.contains("ATOMIC_ERROR") == true)
  }

  @Test("conflict description is generic when reason is nil")
  internal func conflictNoReason() {
    let error = DeleteError.conflict(reason: nil)
    #expect(error.errorDescription?.contains("conflict") == true)
  }

  @Test("conflict suggests --force as a remedy")
  internal func conflictRecoveryMentionsForce() {
    let error = DeleteError.conflict(reason: nil)
    #expect(error.recoverySuggestion?.contains("--force") == true)
  }
}

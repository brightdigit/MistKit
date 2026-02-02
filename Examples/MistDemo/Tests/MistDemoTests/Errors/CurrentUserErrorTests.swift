//
//  CurrentUserErrorTests.swift
//  MistDemo
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
@testable import MistDemo

@Suite("CurrentUserError Tests")
struct CurrentUserErrorTests {

    // MARK: - Error Description Tests

    @Test("operationFailed error description")
    func operationFailedDescription() {
        let error = CurrentUserError.operationFailed("network timeout")
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description?.contains("Current user operation failed") == true)
        #expect(description?.contains("network timeout") == true)
    }

    @Test("authenticationRequired error description")
    func authenticationRequiredDescription() {
        let error = CurrentUserError.authenticationRequired
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description?.contains("Authentication is required") == true)
        #expect(description?.contains("current-user") == true)
        #expect(description?.contains("auth-token") == true)
    }

    // MARK: - LocalizedError Conformance Tests

    @Test("CurrentUserError conforms to LocalizedError")
    func conformsToLocalizedError() {
        let error: any Error = CurrentUserError.authenticationRequired
        #expect(error is LocalizedError)
    }

    @Test("All error cases have non-nil descriptions")
    func allCasesHaveDescriptions() {
        let errors: [CurrentUserError] = [
            .operationFailed("test reason"),
            .authenticationRequired
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    // MARK: - Error Throwing Tests

    @Test("Can throw and catch CurrentUserError")
    func throwAndCatch() {
        #expect(throws: CurrentUserError.self) {
            throw CurrentUserError.authenticationRequired
        }
    }

    @Test("Can pattern match on specific error case")
    func patternMatch() {
        let error = CurrentUserError.operationFailed("test")

        if case .operationFailed(let message) = error {
            #expect(message == "test")
        } else {
            Issue.record("Pattern match failed")
        }
    }

    // MARK: - Error Message Content Tests

    @Test("authenticationRequired provides recovery suggestion")
    func authenticationRequiredSuggestion() {
        let error = CurrentUserError.authenticationRequired
        let description = error.errorDescription!

        #expect(description.contains("auth-token"))
        #expect(description.contains("--web-auth-token"))
    }

    @Test("operationFailed includes error message")
    func operationFailedIncludesMessage() {
        let message = "Server returned 500"
        let error = CurrentUserError.operationFailed(message)
        let description = error.errorDescription!

        #expect(description.contains(message))
    }

    // MARK: - Error Type Tests

    @Test("Different error cases are distinguishable")
    func errorCasesDistinguishable() {
        let error1 = CurrentUserError.authenticationRequired
        let error2 = CurrentUserError.operationFailed("test")

        if case .authenticationRequired = error1 {
            // Success
        } else {
            Issue.record("Error case mismatch")
        }

        if case .operationFailed = error2 {
            // Success
        } else {
            Issue.record("Error case mismatch")
        }
    }
}

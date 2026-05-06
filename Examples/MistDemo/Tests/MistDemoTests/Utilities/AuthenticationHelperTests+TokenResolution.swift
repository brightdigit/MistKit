//
//  AuthenticationHelperTests+TokenResolution.swift
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

@testable import MistDemoKit
@testable import MistKit

extension AuthenticationHelperTests {
  @Suite("Token Resolution")
  internal struct TokenResolution {
    @Test("resolveAPIToken returns provided token when not empty", .mockEnvironment([:]))
    internal func resolveAPITokenReturnsProvidedToken() {
      let token = "my-api-token"
      let resolved = AuthenticationHelper.resolveAPIToken(
        token, environment: MockEnvironment.reader)
      #expect(resolved == token)
    }

    @Test(
      "resolveAPIToken checks environment when empty",
      .mockEnvironment(["CLOUDKIT_API_TOKEN": "env-api-token"])
    )
    internal func resolveAPITokenChecksEnvironment() {
      let resolved = AuthenticationHelper.resolveAPIToken("", environment: MockEnvironment.reader)
      #expect(resolved == "env-api-token")
    }

    @Test("resolveWebAuthToken returns provided token when not empty", .mockEnvironment([:]))
    internal func resolveWebAuthTokenReturnsProvidedToken() {
      let token = "my-web-auth-token"
      let resolved = AuthenticationHelper.resolveWebAuthToken(
        token, environment: MockEnvironment.reader)
      #expect(resolved == token)
    }

    @Test("resolveWebAuthToken returns nil for empty string", .mockEnvironment([:]))
    internal func resolveWebAuthTokenReturnsNilForEmpty() {
      let resolved = AuthenticationHelper.resolveWebAuthToken(
        "", environment: MockEnvironment.reader)
      #expect(resolved == nil)
    }

    @Test(
      "resolveWebAuthToken checks environment variable",
      .mockEnvironment(["CLOUDKIT_WEB_AUTH_TOKEN": "env-token"])
    )
    internal func resolveWebAuthTokenChecksEnvironment() {
      let resolved = AuthenticationHelper.resolveWebAuthToken(
        "", environment: MockEnvironment.reader)
      #expect(resolved == "env-token")
    }
  }
}

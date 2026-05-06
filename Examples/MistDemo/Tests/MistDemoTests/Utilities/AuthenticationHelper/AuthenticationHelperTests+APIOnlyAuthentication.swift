//
//  AuthenticationHelperTests+APIOnlyAuthentication.swift
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
  @Suite("API-Only Authentication")
  internal struct APIOnlyAuthentication {
    @Test("API-only auth enforces public database")
    internal func apiOnlyEnforcesPublicDatabase() async throws {
      do {
        let result = try await AuthenticationHelper.setupAuthentication(
          apiToken: "test-api-token",
          webAuthToken: nil,
          keyID: nil,
          privateKey: nil,
          privateKeyFile: nil,
          databaseOverride: nil
        )

        #expect(result.database == .public)
        #expect(result.authMethod.contains("API-only"))
      } catch AuthenticationError.invalidAPIToken {
        // Expected with test token
      } catch is TokenManagerError {
        // Expected - MistKit validates token format before AuthenticationHelper wraps it
      }
    }

    @Test("API-only auth throws on private database request")
    internal func apiOnlyThrowsOnPrivateDatabaseRequest() async throws {
      do {
        _ = try await AuthenticationHelper.setupAuthentication(
          apiToken: "test-api-token",
          webAuthToken: nil,
          keyID: nil,
          privateKey: nil,
          privateKeyFile: nil,
          databaseOverride: "private"
        )
        Issue.record("Expected privateRequiresWebAuth error")
      } catch let error as AuthenticationError {
        if case .privateRequiresWebAuth = error {
          // Expected error - test passes
        } else {
          Issue.record("Expected privateRequiresWebAuth, got \(error)")
        }
      }
    }
  }
}

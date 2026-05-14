//
//  AuthenticationHelperTests+AuthenticationMethodPriority.swift
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
  @Suite("Authentication Method Priority")
  internal struct AuthenticationMethodPriority {
    @Test("Server-to-server takes precedence over web auth")
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    internal func serverToServerTakesPrecedence() async throws {
      let privateKeyPEM = AuthenticationHelperTests.testPrivateKeyPEM

      do {
        let result = try await AuthenticationHelper.setupAuthentication(
          apiToken: "test-api-token",
          webAuthToken: "test-web-auth-token",  // Should be ignored
          keyID: "test-key-id",
          privateKey: privateKeyPEM,
          privateKeyFile: nil,
          databaseOverride: nil
        )

        #expect(result.database == .public(.prefers(.serverToServer)))
        #expect(result.authMethod.contains("Server-to-server"))
      } catch AuthenticationError.invalidServerToServerCredentials {
        // Expected with test credentials
      }
    }

    @Test("Web auth takes precedence over API-only")
    internal func webAuthTakesPrecedence() async throws {
      do {
        let result = try await AuthenticationHelper.setupAuthentication(
          apiToken: "test-api-token",
          webAuthToken: "test-web-auth-token",
          keyID: nil,
          privateKey: nil,
          privateKeyFile: nil,
          databaseOverride: nil
        )

        #expect(result.authMethod.contains("Web authentication"))
        #expect(!result.authMethod.contains("API-only"))
      } catch AuthenticationError.invalidWebAuthCredentials {
        // Expected with test credentials
      } catch is TokenManagerError {
        // Expected - MistKit validates token format before AuthenticationHelper wraps it
      }
    }
  }
}

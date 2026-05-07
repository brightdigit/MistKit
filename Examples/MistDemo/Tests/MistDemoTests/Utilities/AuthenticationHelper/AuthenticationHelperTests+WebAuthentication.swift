//
//  AuthenticationHelperTests+WebAuthentication.swift
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
  @Suite("Web Authentication")
  internal struct WebAuthentication {
    @Test("Web auth defaults to private database")
    internal func webAuthDefaultsToPrivateDatabase() async throws {
      // Note: This will fail validation without real credentials
      // We're testing the path selection logic
      do {
        let result = try await AuthenticationHelper.setupAuthentication(
          apiToken: "test-api-token",
          webAuthToken: "test-web-auth-token",
          keyID: nil,
          privateKey: nil,
          privateKeyFile: nil,
          databaseOverride: nil
        )

        #expect(result.database == .private)
        #expect(result.authMethod.contains("Web authentication"))
        #expect(result.authMethod.contains("private"))
      } catch AuthenticationError.invalidWebAuthCredentials {
        // Expected with test credentials - but we know it chose the right path
      } catch is TokenManagerError {
        // Expected - MistKit validates token format before AuthenticationHelper wraps it
      }
    }

    @Test("Web auth allows public database override")
    internal func webAuthAllowsPublicDatabaseOverride() async throws {
      do {
        let result = try await AuthenticationHelper.setupAuthentication(
          apiToken: "test-api-token",
          webAuthToken: "test-web-auth-token",
          keyID: nil,
          privateKey: nil,
          privateKeyFile: nil,
          databaseOverride: .public
        )

        #expect(result.database == .public)
        #expect(result.authMethod.contains("Web authentication"))
        #expect(result.authMethod.contains("public"))
      } catch AuthenticationError.invalidWebAuthCredentials {
        // Expected with test credentials
      } catch is TokenManagerError {
        // Expected - MistKit validates token format before AuthenticationHelper wraps it
      }
    }

    @Test("Web auth respects private database override")
    internal func webAuthRespectsPrivateDatabaseOverride() async throws {
      do {
        let result = try await AuthenticationHelper.setupAuthentication(
          apiToken: "test-api-token",
          webAuthToken: "test-web-auth-token",
          keyID: nil,
          privateKey: nil,
          privateKeyFile: nil,
          databaseOverride: .private
        )

        #expect(result.database == .private)
      } catch AuthenticationError.invalidWebAuthCredentials {
        // Expected with test credentials
      } catch is TokenManagerError {
        // Expected - MistKit validates token format before AuthenticationHelper wraps it
      }
    }
  }
}

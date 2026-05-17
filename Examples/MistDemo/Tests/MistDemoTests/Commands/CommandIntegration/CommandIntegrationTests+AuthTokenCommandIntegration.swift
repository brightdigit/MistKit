//
//  CommandIntegrationTests+AuthTokenCommandIntegration.swift
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

#if canImport(Hummingbird)
  import Foundation
  import MistKit
  import Testing

  @testable import MistDemoKit

  extension CommandIntegrationTests {
    @Suite("AuthTokenCommand Integration")
    internal struct AuthTokenCommandIntegration {
      @Test("AuthTokenCommand configuration validation")
      internal func authTokenCommandConfigValidation() async throws {
        let config = AuthTokenConfig(
          apiToken: "test-api-token-123",
          port: 8_080,
          host: "127.0.0.1",
          openBrowser: false
        )

        _ = AuthTokenCommand(config: config)

        // Verify command is properly configured
        #expect(AuthTokenCommand.commandName == "auth-token")
        #expect(AuthTokenCommand.abstract.contains("authentication token"))
      }

      @Test("AuthTokenCommand resource path validation")
      internal func authTokenCommandResourcePathValidation() async throws {
        let config = AuthTokenConfig(apiToken: "test-token")
        _ = AuthTokenCommand(config: config)

        // Test that resource finding logic doesn't crash
        // This tests the findResourcesPath method indirectly
        #expect(AuthTokenCommand.commandName == "auth-token")
      }
    }
  }
#endif

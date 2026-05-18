//
//  MistKitClientFactoryTests+ServerToServerAuth.swift
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
import MistKit
import Testing

@testable import MistDemoKit

extension MistKitClientFactoryTests {
  @Suite("Server-to-Server Auth")
  internal struct ServerToServerAuth {
    @Test("Create client with server-to-server auth")
    internal func createWithServerToServerAuth() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        apiToken: "api-token",
        keyID: "test-key-id",
        privateKey: MistKitClientFactoryTests.validPrivateKey
      )

      let client = try MistKitClientFactory.create(for: config)

      #expect(client != nil)
    }

    @Test("Throw error when server-to-server auth incomplete")
    internal func throwErrorWhenServerToServerIncomplete() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        apiToken: "api-token",
        keyID: "test-key-id"
          // privateKey missing
      )

      // Should fall back to API-only auth
      let client = try? MistKitClientFactory.create(for: config)
      #expect(client != nil)
    }
  }
}

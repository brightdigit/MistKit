//
//  MistKitClientFactoryTests+PublicDatabase.swift
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
  @Suite("Public Database")
  internal struct PublicDatabase {
    @Test("Create client for public database")
    internal func createForPublicDatabaseTest() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        apiToken: "api-token", database: .public(.prefers(.serverToServer))
      )
      let tokenManager = APITokenManager(apiToken: "api-token")

      let client = try MistKitClientFactory.create(
        from: config,
        tokenManager: tokenManager
      )

      #expect(client != nil)
    }

    @Test("Public database creation requires API token")
    internal func publicDatabaseRequiresAPIToken() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        apiToken: "", database: .public(.prefers(.serverToServer))
      )

      #expect(throws: ConfigurationError.self) {
        try MistKitClientFactory.create(for: config)
      }
    }
  }
}

//
//  CloudKitServiceTests.Tokens+SuccessCases.swift
//  MistKit
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

internal import Foundation
internal import Testing

@testable import MistKit

extension CloudKitServiceTests.Tokens {
  @Suite("Success Cases")
  internal struct SuccessCases {
    private static let database: Database = .public(.prefers(.serverToServer))

    @Test("createAPNsToken() decodes apnsEnvironment, apnsToken, webcourierURL")
    internal func createDecodesTokens() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let json = #"""
        {
          "apnsEnvironment": "development",
          "apnsToken": "apns-123",
          "webcourierURL": "https://webcourier.icloud.com/abc"
        }
        """#
      let service = try CloudKitServiceTests.Tokens.makeService(json: json)

      let result = try await service.createAPNsToken(
        environment: .development,
        database: Self.database
      )
      #expect(result.environment == .development)
      #expect(result.apnsToken == "apns-123")
      #expect(result.webcourierURL == URL(string: "https://webcourier.icloud.com/abc"))
    }

    @Test("registerAPNsToken() completes against an empty 200")
    internal func registerCompletes() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.Tokens.makeService()
      try await service.registerAPNsToken(
        "abcdef0123456789",
        environment: .development,
        database: Self.database
      )
    }

    @Test("registerAPNsToken() rejects an empty token before dispatching")
    internal func registerRejectsEmpty() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.Tokens.makeService()
      await #expect(throws: CloudKitError.self) {
        try await service.registerAPNsToken(
          "   ",
          environment: .development,
          database: Self.database
        )
      }
    }
  }
}

//
//  CloudKitServiceTests.Tokens+FailureCases.swift
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
  @Suite("Failure Cases")
  internal struct FailureCases {
    private static let database: Database = .public(.prefers(.serverToServer))

    private static let badRequestJSON = #"""
      { "serverErrorCode": "BAD_REQUEST", "reason": "clientId is required" }
      """#

    private static let authFailedJSON = #"""
      { "serverErrorCode": "AUTHENTICATION_FAILED", "reason": "bad token" }
      """#

    @Test("createAPNsToken() maps a 400 BAD_REQUEST to .badRequest")
    internal func createMapsBadRequest() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.Tokens.makeService(
        statusCode: 400,
        json: Self.badRequestJSON
      )

      do {
        _ = try await service.createAPNsToken(
          environment: .development,
          database: Self.database
        )
        Issue.record("expected createAPNsToken to throw")
      } catch let error as CloudKitError {
        guard case .badRequest(let reason) = error else {
          Issue.record("expected .badRequest, got \(error)")
          return
        }
        #expect(reason == "clientId is required")
      }
    }

    @Test("createAPNsToken() maps a 401 to .httpErrorWithDetails")
    internal func createMapsUnauthorized() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.Tokens.makeService(
        statusCode: 401,
        json: Self.authFailedJSON
      )

      do {
        _ = try await service.createAPNsToken(
          environment: .development,
          database: Self.database
        )
        Issue.record("expected createAPNsToken to throw")
      } catch let error as CloudKitError {
        guard case .httpErrorWithDetails(let statusCode, let serverErrorCode, _) = error else {
          Issue.record("expected .httpErrorWithDetails, got \(error)")
          return
        }
        #expect(statusCode == 401)
        #expect(serverErrorCode == "AUTHENTICATION_FAILED")
      }
    }

    @Test("registerAPNsToken() maps a 400 BAD_REQUEST to .badRequest")
    internal func registerMapsBadRequest() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.Tokens.makeService(
        statusCode: 400,
        json: Self.badRequestJSON
      )

      do {
        try await service.registerAPNsToken(
          "abcdef0123456789",
          environment: .development,
          database: Self.database
        )
        Issue.record("expected registerAPNsToken to throw")
      } catch let error as CloudKitError {
        guard case .badRequest = error else {
          Issue.record("expected .badRequest, got \(error)")
          return
        }
      }
    }
  }
}

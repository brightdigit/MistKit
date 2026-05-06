//
//  CloudKitServiceFetchZoneChangesTests+ErrorHandling.swift
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

import Foundation
import Testing

@testable import MistKit

extension CloudKitServiceFetchZoneChangesTests {
  @Suite("Error Handling")
  internal struct ErrorHandling {
    private static let testAPIToken =
      TestConstants.apiToken

    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    private static func makeService(provider: ResponseProvider) throws -> CloudKitService {
      let transport = MockTransport(responseProvider: provider)
      return try CloudKitService(
        containerIdentifier: TestConstants.serviceContainerIdentifier,
        apiToken: testAPIToken,
        transport: transport
      )
    }

    @Test("fetchZoneChanges() rejects an invalid sync token with BAD_REQUEST")
    internal func fetchZoneChangesRejectsInvalidSyncToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let provider = ResponseProvider(
        defaultResponse: .cloudKitError(
          statusCode: 400,
          serverErrorCode: "BAD_REQUEST",
          reason: "Invalid syncToken format"
        )
      )
      let service = try Self.makeService(provider: provider)

      await #expect {
        _ = try await service.fetchZoneChanges(syncToken: "garbage-token")
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .httpErrorWithDetails(let statusCode, let serverErrorCode, let reason) = ckError
        else { return false }
        return statusCode == 400
          && serverErrorCode == "BAD_REQUEST"
          && reason?.contains("Invalid syncToken") == true
      }
    }

    @Test("fetchZoneChanges() reports an expired sync token via CloudKitError")
    internal func fetchZoneChangesReportsExpiredSyncToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      // CloudKit returns 421 with "ZONE_NOT_FOUND" or similar; we use the SYNC_TOKEN_EXPIRED
      // server error code documented in the CloudKit Web Services spec.
      let provider = ResponseProvider(
        defaultResponse: .cloudKitError(
          statusCode: 400,
          serverErrorCode: "BAD_REQUEST",
          reason: "syncToken has expired and the zone must be re-fetched from the beginning"
        )
      )
      let service = try Self.makeService(provider: provider)

      await #expect {
        _ = try await service.fetchZoneChanges(syncToken: "expired-token")
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .httpErrorWithDetails(let statusCode, let serverErrorCode, let reason) = ckError
        else { return false }
        return statusCode == 400
          && serverErrorCode == "BAD_REQUEST"
          && reason?.contains("expired") == true
      }
    }

    @Test("fetchZoneChanges() surfaces network connection failure as networkError")
    internal func fetchZoneChangesPropagatesConnectionLost() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Self.makeService(provider: ResponseProvider.connectionLost())

      await #expect {
        _ = try await service.fetchZoneChanges()
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .networkError(let urlError) = ckError
        else { return false }
        return urlError.code == .networkConnectionLost
      }
    }
  }
}

//
//  CloudKitServiceFetchChangesTests+Validation.swift
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

extension CloudKitServiceFetchChangesTests {
  @Suite("Validation")
  internal struct Validation {
    @Test("fetchRecordChanges() throws 400 for limit of 0")
    internal func fetchRecordChangesThrowsForZeroLimit() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceFetchChangesTests.makeSuccessfulService()

      await #expect {
        try await service.fetchRecordChanges(resultsLimit: 0)
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .httpErrorWithRawResponse(let status, _) = ckError
        else { return false }
        return status == 400
      }
    }

    @Test("fetchRecordChanges() throws 400 for limit over 200")
    internal func fetchRecordChangesThrowsForLimitOver200() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceFetchChangesTests.makeSuccessfulService()

      await #expect {
        try await service.fetchRecordChanges(resultsLimit: 201)
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .httpErrorWithRawResponse(let status, _) = ckError
        else { return false }
        return status == 400
      }
    }

    @Test("fetchRecordChanges() accepts valid limit values")
    internal func fetchRecordChangesAcceptsValidLimits() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceFetchChangesTests.makeSuccessfulService()

      // Minimum valid limit
      let result1 = try await service.fetchRecordChanges(resultsLimit: 1)
      #expect(result1.records.isEmpty == false || result1.syncToken != nil)

      // Maximum valid limit
      let result200 = try await service.fetchRecordChanges(resultsLimit: 200)
      #expect(result200.records.isEmpty == false || result200.syncToken != nil)
    }

    @Test("fetchAllRecordChanges() throws invalidResponse for moreComing:true with nil syncToken")
    internal func fetchAllRecordChangesThrowsForNilSyncTokenWithMoreComing() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let responseProvider = ResponseProvider(
        defaultResponse: .fetchChangesResponseMoreComingNilToken(recordCount: 2)
      )
      let transport = MockTransport(responseProvider: responseProvider)
      let service = try CloudKitService(
        containerIdentifier: "iCloud.com.example.test",
        apiToken: "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234",
        transport: transport
      )

      await #expect(throws: CloudKitError.self) {
        _ = try await service.fetchAllRecordChanges()
      }
    }

    @Test("fetchAllRecordChanges() breaks out when server returns stuck token with no records")
    internal func fetchAllRecordChangesEscapesStuckToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceFetchChangesTests.makeSuccessfulService(
        recordCount: 0,
        moreComing: true,
        syncToken: "stuck-token"
      )

      let (records, token) = try await service.fetchAllRecordChanges()

      #expect(records.isEmpty)
      #expect(token == "stuck-token")
    }
  }
}

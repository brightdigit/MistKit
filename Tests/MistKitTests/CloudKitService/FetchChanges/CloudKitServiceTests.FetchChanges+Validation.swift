//
//  CloudKitServiceTests.FetchChanges+Validation.swift
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

extension CloudKitServiceTests.FetchChanges {
  @Suite("Validation")
  internal struct Validation {
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
        containerIdentifier: TestConstants.serviceContainerIdentifier,
        credentials: Credentials(apiAuth: APICredentials(apiToken: TestConstants.apiToken)),
        transport: transport
      )

      await #expect(throws: CloudKitError.self) {
        _ = try await service.fetchAllRecordChanges(database: .public(.prefers(.serverToServer)))
      }
    }

    @Test("fetchAllRecordChanges() breaks out when server returns stuck token with no records")
    internal func fetchAllRecordChangesEscapesStuckToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.FetchChanges.makeSuccessfulService(
        recordCount: 0,
        moreComing: true,
        syncToken: "stuck-token"
      )

      let (records, token) = try await service.fetchAllRecordChanges(
        database: .public(.prefers(.serverToServer))
      )

      #expect(records.isEmpty)
      #expect(token == "stuck-token")
    }
  }
}

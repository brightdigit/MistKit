//
//  CloudKitServiceTests.BatchChunking+UserIdentityChunking.swift
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

extension CloudKitServiceTests.BatchChunking {
  @Suite("User-identity chunking")
  internal struct UserIdentityChunking {
    private static let identitiesPerCall = 2

    private static func makeService() throws -> (CloudKitService, ResponseProvider) {
      let provider = ResponseProvider(
        defaultResponse: try .successfulDiscoverUserIdentitiesResponse(
          identityCount: identitiesPerCall
        )
      )
      let service = try CloudKitServiceTests.BatchChunking.makeUserService(provider: provider)
      return (service, provider)
    }

    // MARK: - discoverAllUserIdentities(lookupInfos:)

    @Test("discoverAllUserIdentities chunks, accumulates, and preserves order")
    internal func discoverMultiBatch() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let (service, provider) = try Self.makeService()
      let infos = (0..<450).map { UserIdentityLookupInfo(userRecordName: "_user-\($0)") }

      let identities = try await service.discoverAllUserIdentities(lookupInfos: infos)

      let bodies = await provider.bodies(for: "discoverUserIdentities")
      let sizes = CloudKitServiceTests.BatchChunking.itemCounts(in: bodies, key: "lookupInfos")
      let order = CloudKitServiceTests.BatchChunking.orderedValues(
        in: bodies,
        key: "lookupInfos",
        field: "userRecordName"
      )
      #expect(await provider.callCount(for: "discoverUserIdentities") == 3)
      #expect(sizes == [200, 200, 50])
      #expect(order == infos.map { $0.userRecordName ?? "" })
      #expect(identities.count == 3 * Self.identitiesPerCall)
    }

    @Test("discoverAllUserIdentities clamps batchSize to the per-request cap")
    internal func discoverClampsBatchSize() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let (service, provider) = try Self.makeService()
      let infos = (0..<250).map { UserIdentityLookupInfo(userRecordName: "_user-\($0)") }

      _ = try await service.discoverAllUserIdentities(lookupInfos: infos, batchSize: 9_999)

      let sizes = CloudKitServiceTests.BatchChunking.itemCounts(
        in: await provider.bodies(for: "discoverUserIdentities"),
        key: "lookupInfos"
      )
      #expect(sizes == [200, 50])
    }

    @Test("discoverAllUserIdentities issues no requests for empty input")
    internal func discoverEmptyInput() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let (service, provider) = try Self.makeService()

      let identities = try await service.discoverAllUserIdentities(lookupInfos: [])

      #expect(identities.isEmpty)
      #expect(await provider.callCount(for: "discoverUserIdentities") == 0)
    }
  }
}

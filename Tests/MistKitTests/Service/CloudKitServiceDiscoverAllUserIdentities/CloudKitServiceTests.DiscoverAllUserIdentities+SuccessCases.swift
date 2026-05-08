//
//  CloudKitServiceTests.DiscoverAllUserIdentities+SuccessCases.swift
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

extension CloudKitServiceTests.DiscoverAllUserIdentities {
  @Suite("Success Cases")
  internal struct SuccessCases {
    @Test("discoverAllUserIdentities() returns a single identity")
    internal func returnsSingleIdentity() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.DiscoverAllUserIdentities
        .makeSuccessfulService(identityCount: 1)

      let identities = try await service.discoverAllUserIdentities()

      #expect(identities.count == 1)
      #expect(identities.first?.userRecordName == "_user-0")
    }

    @Test("discoverAllUserIdentities() returns multiple identities")
    internal func returnsMultipleIdentities() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.DiscoverAllUserIdentities
        .makeSuccessfulService(identityCount: 3)

      let identities = try await service.discoverAllUserIdentities()

      #expect(identities.count == 3)
      #expect(identities[0].userRecordName == "_user-0")
      #expect(identities[1].userRecordName == "_user-1")
      #expect(identities[2].userRecordName == "_user-2")
    }

    @Test("discoverAllUserIdentities() returns empty array when address book is empty")
    internal func returnsEmptyArray() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.DiscoverAllUserIdentities
        .makeSuccessfulService(identityCount: 0)

      let identities = try await service.discoverAllUserIdentities()

      #expect(identities.isEmpty)
    }
  }
}

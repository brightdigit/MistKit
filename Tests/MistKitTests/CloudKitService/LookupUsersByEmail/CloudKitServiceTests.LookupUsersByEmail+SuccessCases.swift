//
//  CloudKitServiceTests.LookupUsersByEmail+SuccessCases.swift
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

extension CloudKitServiceTests.LookupUsersByEmail {
  @Suite("Success Cases")
  internal struct SuccessCases {
    @Test("lookupUsersByEmail() returns a single identity")
    internal func returnsSingleIdentity() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.LookupUsersByEmail
        .makeSuccessfulService(identityCount: 1)

      let identities = try await service.lookupUsersByEmail(["user@example.com"])

      #expect(identities.count == 1)
      #expect(identities.first?.userRecordName == .recordName("_user-0"))
    }

    @Test("lookupUsersByEmail() returns multiple identities")
    internal func returnsMultipleIdentities() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.LookupUsersByEmail
        .makeSuccessfulService(identityCount: 3)

      let identities = try await service.lookupUsersByEmail([
        "a@example.com",
        "b@example.com",
        "c@example.com",
      ])

      #expect(identities.count == 3)
    }

    @Test("lookupUsersByEmail() returns empty array when no matches")
    internal func returnsEmptyArray() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.LookupUsersByEmail
        .makeSuccessfulService(identityCount: 0)

      let identities = try await service.lookupUsersByEmail(["unknown@example.com"])

      #expect(identities.isEmpty)
    }
  }
}

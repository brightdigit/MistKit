//
//  CloudKitServiceTests.FetchCaller+SuccessCases.swift
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

extension CloudKitServiceTests.FetchCaller {
  @Suite("Success Cases")
  internal struct SuccessCases {
    @Test("fetchCaller() returns the caller's user info")
    internal func returnsCallerInfo() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.FetchCaller.makeSuccessfulService(
        userRecordName: "_user-caller",
        firstName: "Test",
        lastName: "User",
        emailAddress: "caller@example.com"
      )

      let userInfo = try await service.fetchCaller()

      #expect(userInfo.userRecordName == "_user-caller")
      #expect(userInfo.firstName == "Test")
      #expect(userInfo.lastName == "User")
      #expect(userInfo.emailAddress == "caller@example.com")
    }

    @Test("fetchCaller() omits optional fields when absent in response")
    internal func handlesOmittedOptionalFields() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.FetchCaller.makeSuccessfulService(
        userRecordName: "_user-anon",
        firstName: nil,
        lastName: nil,
        emailAddress: nil
      )

      let userInfo = try await service.fetchCaller()

      #expect(userInfo.userRecordName == "_user-anon")
      #expect(userInfo.firstName == nil)
      #expect(userInfo.lastName == nil)
      #expect(userInfo.emailAddress == nil)
    }
  }
}

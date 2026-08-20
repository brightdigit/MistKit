//
//  MockBackend+UserOperations.swift
//  MistDemoTests
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

#if canImport(Hummingbird)
  internal import MistKit

  @testable import MistDemoKit

  extension MockBackend {
    internal func webFetchCaller() async throws -> UserInfo {
      didFetchCaller = true
      try consumePendingError()
      return UserInfo(
        userRecordName: "stub-caller",
        firstName: "Stub",
        lastName: "Caller",
        emailAddress: "stub@example.com"
      )
    }

    internal func webDiscoverUsers(
      emails: [String],
      phoneNumbers: [String],
      userRecordNames: [String]
    ) async throws -> [UserIdentity] {
      lastDiscoverUsers = DiscoverUsersCall(
        emails: emails,
        phoneNumbers: phoneNumbers,
        userRecordNames: userRecordNames
      )
      try consumePendingError()
      return emails.map { email in
        UserIdentity(lookupInfo: UserIdentityLookupInfo(emailAddress: email))
      }
        + phoneNumbers.map { phoneNumber in
          UserIdentity(
            lookupInfo: UserIdentityLookupInfo(phoneNumber: phoneNumber)
          )
        }
        + userRecordNames.map { name in
          UserIdentity(userRecordName: .recordName(name))
        }
    }
  }
#endif

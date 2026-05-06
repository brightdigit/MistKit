//
//  CloudKitServiceDiscoverUserIdentitiesTests+InvalidEmail.swift
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

extension CloudKitServiceDiscoverUserIdentitiesTests {
  @Suite("Invalid Email")
  internal struct InvalidEmail {
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

    @Test("discoverUserIdentities() surfaces server BAD_REQUEST for malformed email")
    internal func discoverUserIdentitiesRejectsMalformedEmail() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let provider = ResponseProvider(
        defaultResponse: .cloudKitError(
          statusCode: 400,
          serverErrorCode: "BAD_REQUEST",
          reason: "Invalid email address format: not-an-email"
        )
      )
      let service = try Self.makeService(provider: provider)
      let lookup = UserIdentityLookupInfo(emailAddress: "not-an-email")

      await #expect {
        _ = try await service.discoverUserIdentities(lookupInfos: [lookup])
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .httpErrorWithDetails(let statusCode, let serverErrorCode, let reason) = ckError
        else { return false }
        return statusCode == 400
          && serverErrorCode == "BAD_REQUEST"
          && reason?.contains("Invalid email") == true
      }
    }
  }
}

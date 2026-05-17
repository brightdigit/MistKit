//
//  CloudKitServiceTests.FetchCaller+Validation.swift
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
  @Suite("Validation")
  internal struct Validation {
    @Test("fetchCaller() throws on authentication error")
    internal func throwsOnAuthError() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceTests.FetchCaller.makeAuthErrorService()

      await #expect(throws: CloudKitError.self) {
        try await service.fetchCaller()
      }
    }

    @Test("fetchCaller() throws missingCredentials when web-auth is absent")
    internal func throwsWhenWebAuthMissing() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      // A service with API token only (no webAuthToken) cannot satisfy the
      // user-context requirement of fetchCaller. The resolver should throw
      // before any HTTP request is dispatched.
      let provider = ResponseProvider(
        defaultResponse: try .successfulFetchCallerResponse()
      )
      let service = try CloudKitService(
        containerIdentifier: TestConstants.serviceContainerIdentifier,
        credentials: Credentials(
          apiAuth: APICredentials(apiToken: TestConstants.apiToken)
        ),
        transport: MockTransport(responseProvider: provider)
      )

      await #expect {
        _ = try await service.fetchCaller()
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .missingCredentials = ckError
        else { return false }
        return true
      }
    }
  }
}

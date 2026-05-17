//
//  CredentialsTokenManagerTests+UserContext.swift
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

extension CredentialsTokenManagerTests {
  /// Coverage for the "user-context" routes (`users/caller`,
  /// `users/lookup/*`, `users/discover`). With the per-call
  /// `PublicAuthPreference` rewrite these no longer take a separate
  /// `requiresUserContext` flag — they pass `.public(.requires(.webAuth))`
  /// directly to the dispatcher.
  @Suite("User-Context Branch")
  internal struct UserContext {
    @Test(".public(.requires(.webAuth)) + both creds → web-auth (S2S ignored)")
    internal func requiresWebAuthOnPublicIgnoresS2S() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        serverToServer: CredentialsTokenManagerTests.makeServerToServerCredentials(),
        apiAuth: CredentialsTokenManagerTests.makeAPICredentialsWithWebAuth()
      )
      let manager = try credentials.makeTokenManager(
        for: .public(.requires(.webAuth))
      )
      #expect(manager is WebAuthTokenManager)
    }

    @Test(".public(.requires(.webAuth)) + S2S only → throws preferenceRequired")
    internal func requiresWebAuthWithoutWebAuthThrows() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        serverToServer: CredentialsTokenManagerTests.makeServerToServerCredentials()
      )
      #expect(throws: CloudKitError.self) {
        _ = try credentials.makeTokenManager(
          for: .public(.requires(.webAuth))
        )
      }
    }

    @Test(".public(.requires(.webAuth)) + API token only → throws preferenceRequired")
    internal func requiresWebAuthWithAPITokenOnlyThrows() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        apiAuth: CredentialsTokenManagerTests.makeAPICredentialsTokenOnly()
      )
      #expect(throws: CloudKitError.self) {
        _ = try credentials.makeTokenManager(
          for: .public(.requires(.webAuth))
        )
      }
    }
  }
}

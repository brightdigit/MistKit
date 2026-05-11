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
  @Suite("User-Context Branch")
  internal struct UserContext {
    @Test("requiresUserContext on .public → WebAuthTokenManager")
    internal func userContextOnPublicPicksWebAuth() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        serverToServer: CredentialsTokenManagerTests.makeServerToServerCredentials(),
        apiAuth: CredentialsTokenManagerTests.makeAPICredentialsWithWebAuth()
      )
      let manager = try credentials.makeTokenManager(
        for: .public, requiresUserContext: true
      )
      // S2S is present, but user-context routes ignore it — must pick web-auth.
      #expect(manager is WebAuthTokenManager)
    }

    @Test("requiresUserContext without web-auth → throws missingCredentials")
    internal func userContextWithoutWebAuthThrows() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        serverToServer: CredentialsTokenManagerTests.makeServerToServerCredentials()
      )
      #expect(throws: CloudKitError.self) {
        _ = try credentials.makeTokenManager(
          for: .public, requiresUserContext: true
        )
      }
    }

    @Test("requiresUserContext with apiAuth (token only) → throws missingCredentials")
    internal func userContextWithAPITokenOnlyThrows() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        apiAuth: CredentialsTokenManagerTests.makeAPICredentialsTokenOnly()
      )
      #expect(throws: CloudKitError.self) {
        _ = try credentials.makeTokenManager(
          for: .public, requiresUserContext: true
        )
      }
    }

    @Test("requiresUserContext on .private + web-auth → WebAuthTokenManager")
    internal func userContextOnPrivatePicksWebAuth() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        apiAuth: CredentialsTokenManagerTests.makeAPICredentialsWithWebAuth()
      )
      let manager = try credentials.makeTokenManager(
        for: .private, requiresUserContext: true
      )
      #expect(manager is WebAuthTokenManager)
    }

    @Test("requiresUserContext on .shared + web-auth → WebAuthTokenManager")
    internal func userContextOnSharedPicksWebAuth() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        apiAuth: CredentialsTokenManagerTests.makeAPICredentialsWithWebAuth()
      )
      let manager = try credentials.makeTokenManager(
        for: .shared, requiresUserContext: true
      )
      #expect(manager is WebAuthTokenManager)
    }

    @Test("requiresUserContext on .private + S2S only → throws missingCredentials")
    internal func userContextOnPrivateRejectsServerToServerOnly() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        serverToServer: CredentialsTokenManagerTests.makeServerToServerCredentials()
      )
      #expect(throws: CloudKitError.self) {
        _ = try credentials.makeTokenManager(
          for: .private, requiresUserContext: true
        )
      }
    }

    @Test("requiresUserContext on .shared + S2S only → throws missingCredentials")
    internal func userContextOnSharedRejectsServerToServerOnly() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        serverToServer: CredentialsTokenManagerTests.makeServerToServerCredentials()
      )
      #expect(throws: CloudKitError.self) {
        _ = try credentials.makeTokenManager(
          for: .shared, requiresUserContext: true
        )
      }
    }
  }
}

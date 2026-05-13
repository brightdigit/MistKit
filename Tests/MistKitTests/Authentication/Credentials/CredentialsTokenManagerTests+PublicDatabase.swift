//
//  CredentialsTokenManagerTests+PublicDatabase.swift
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
  @Suite("Public Database")
  internal struct PublicDatabase {
    // MARK: - prefers(.serverToServer)

    @Test(".public(.prefers(.serverToServer)) + S2S only → S2S")
    internal func prefersS2SOnlyS2SPicksS2S() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("ServerToServerAuthManager is not available on this operating system.")
        return
      }
      let credentials = try Credentials(
        serverToServer: CredentialsTokenManagerTests.makeServerToServerCredentials()
      )
      let manager = try credentials.makeTokenManager(
        for: .public(.prefers(.serverToServer))
      )
      #expect(manager is ServerToServerAuthManager)
    }

    @Test(".public(.prefers(.serverToServer)) + both creds → S2S")
    internal func prefersS2SBothCredsPicksS2S() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        serverToServer: CredentialsTokenManagerTests.makeServerToServerCredentials(),
        apiAuth: CredentialsTokenManagerTests.makeAPICredentialsWithWebAuth()
      )
      let manager = try credentials.makeTokenManager(
        for: .public(.prefers(.serverToServer))
      )
      #expect(manager is ServerToServerAuthManager)
    }

    @Test(".public(.prefers(.serverToServer)) + web-auth only → falls back to web-auth")
    internal func prefersS2SOnlyWebAuthFallsBackToWebAuth() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        apiAuth: CredentialsTokenManagerTests.makeAPICredentialsWithWebAuth()
      )
      let manager = try credentials.makeTokenManager(
        for: .public(.prefers(.serverToServer))
      )
      #expect(manager is WebAuthTokenManager)
    }

    @Test(".public(.prefers(.serverToServer)) + API token only → APITokenManager")
    internal func prefersS2SAPITokenOnlyFallsBackToAPIToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        apiAuth: CredentialsTokenManagerTests.makeAPICredentialsTokenOnly()
      )
      let manager = try credentials.makeTokenManager(
        for: .public(.prefers(.serverToServer))
      )
      #expect(manager is APITokenManager)
    }

    // MARK: - prefers(.webAuth)

    @Test(".public(.prefers(.webAuth)) + both creds → web-auth")
    internal func prefersWebAuthBothCredsPicksWebAuth() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        serverToServer: CredentialsTokenManagerTests.makeServerToServerCredentials(),
        apiAuth: CredentialsTokenManagerTests.makeAPICredentialsWithWebAuth()
      )
      let manager = try credentials.makeTokenManager(
        for: .public(.prefers(.webAuth))
      )
      #expect(manager is WebAuthTokenManager)
    }

    @Test(".public(.prefers(.webAuth)) + S2S only → falls back to S2S")
    internal func prefersWebAuthOnlyS2SFallsBackToS2S() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        serverToServer: CredentialsTokenManagerTests.makeServerToServerCredentials()
      )
      let manager = try credentials.makeTokenManager(
        for: .public(.prefers(.webAuth))
      )
      #expect(manager is ServerToServerAuthManager)
    }

    // MARK: - requires(.serverToServer)

    @Test(".public(.requires(.serverToServer)) + both creds → S2S")
    internal func requiresS2SBothCredsPicksS2S() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        serverToServer: CredentialsTokenManagerTests.makeServerToServerCredentials(),
        apiAuth: CredentialsTokenManagerTests.makeAPICredentialsWithWebAuth()
      )
      let manager = try credentials.makeTokenManager(
        for: .public(.requires(.serverToServer))
      )
      #expect(manager is ServerToServerAuthManager)
    }

    @Test(".public(.requires(.serverToServer)) without S2S → throws preferenceRequired")
    internal func requiresS2SWithoutS2SThrowsPreferenceRequired() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        apiAuth: CredentialsTokenManagerTests.makeAPICredentialsWithWebAuth()
      )
      #expect {
        _ = try credentials.makeTokenManager(
          for: .public(.requires(.serverToServer))
        )
      } throws: { error in
        guard
          let cloudKitError = error as? CloudKitError,
          case .missingCredentials(_, let availability, _) = cloudKitError
        else { return false }
        return availability == .preferenceRequired
      }
    }

    // MARK: - requires(.webAuth)

    @Test(".public(.requires(.webAuth)) + both creds → web-auth")
    internal func requiresWebAuthBothCredsPicksWebAuth() async throws {
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

    @Test(".public(.requires(.webAuth)) without web-auth → throws preferenceRequired")
    internal func requiresWebAuthWithoutWebAuthThrowsPreferenceRequired() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        serverToServer: CredentialsTokenManagerTests.makeServerToServerCredentials()
      )
      #expect {
        _ = try credentials.makeTokenManager(
          for: .public(.requires(.webAuth))
        )
      } throws: { error in
        guard
          let cloudKitError = error as? CloudKitError,
          case .missingCredentials(_, let availability, _) = cloudKitError
        else { return false }
        return availability == .preferenceRequired
      }
    }

    // Note: The "no creds at all" path in the dispatcher's resolution table
    // (".prefers + neither mode configured → throws notConfigured") is not
    // tested here because `Credentials.init` asserts that at least one of
    // `serverToServer` or `apiAuth` is populated. Reaching `notConfigured`
    // would require constructing an empty `Credentials`, which the type
    // doesn't permit.
  }
}

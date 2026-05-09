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
    @Test(".public + serverToServer → ServerToServerAuthManager")
    internal func publicPicksServerToServer() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("ServerToServerAuthManager is not available on this operating system.")
        return
      }
      let credentials = try Credentials(
        serverToServer: CredentialsTokenManagerTests.makeServerToServerCredentials()
      )
      let manager = try credentials.makeTokenManager(for: .public)
      #expect(manager is ServerToServerAuthManager)
    }

    @Test(".public + apiAuth.webAuthToken → WebAuthTokenManager")
    internal func publicPicksWebAuthOverAPIToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        apiAuth: CredentialsTokenManagerTests.makeAPICredentialsWithWebAuth()
      )
      let manager = try credentials.makeTokenManager(for: .public)
      #expect(manager is WebAuthTokenManager)
    }

    @Test(".public + apiAuth (token only) → APITokenManager")
    internal func publicPicksAPITokenWhenNoWebAuth() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        apiAuth: CredentialsTokenManagerTests.makeAPICredentialsTokenOnly()
      )
      let manager = try credentials.makeTokenManager(for: .public)
      #expect(manager is APITokenManager)
    }

    @Test(".public + serverToServer prefers S2S over apiAuth")
    internal func publicPrefersServerToServerOverAPIAuth() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let credentials = try Credentials(
        serverToServer: CredentialsTokenManagerTests.makeServerToServerCredentials(),
        apiAuth: CredentialsTokenManagerTests.makeAPICredentialsWithWebAuth()
      )
      let manager = try credentials.makeTokenManager(for: .public)
      #expect(manager is ServerToServerAuthManager)
    }
  }
}

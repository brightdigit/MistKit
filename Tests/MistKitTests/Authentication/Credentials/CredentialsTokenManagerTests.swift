//
//  CredentialsTokenManagerTests.swift
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

import Crypto
import Foundation
import Testing

@testable import MistKit

/// Direct unit coverage for `Credentials.makeTokenManager(for:requiresUserContext:)`.
///
/// Each `CloudKitService` operation calls this resolver to pick a token
/// manager based on the target database and whether the route requires
/// user-context auth. The sub-suites below cover every cell of the routing
/// matrix: the four combinations on `.public` plus the two error cases on
/// `.private`/`.shared`, the user-context branch, and PEM-load failure.
@Suite("Credentials.makeTokenManager", .enabled(if: Platform.isCryptoAvailable))
internal enum CredentialsTokenManagerTests {
  internal static func makeServerToServerCredentials() -> ServerToServerCredentials {
    if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
      let pem = P256.Signing.PrivateKey().pemRepresentation
      return ServerToServerCredentials(
        keyID: "test-key-id-12345678",
        privateKey: .raw(pem)
      )
    } else {
      Issue.record(
        "ServerToServerCredentials requires macOS 11.0+ / iOS 14.0+ / tvOS 14.0+ / watchOS 7.0+"
      )
      return ServerToServerCredentials(keyID: "unavailable", privateKey: .raw(""))
    }
  }

  internal static func makeAPICredentialsWithWebAuth() -> APICredentials {
    APICredentials(
      apiToken: TestConstants.apiToken,
      webAuthToken: TestConstants.webAuthToken
    )
  }

  internal static func makeAPICredentialsTokenOnly() -> APICredentials {
    APICredentials(apiToken: TestConstants.apiToken)
  }
}

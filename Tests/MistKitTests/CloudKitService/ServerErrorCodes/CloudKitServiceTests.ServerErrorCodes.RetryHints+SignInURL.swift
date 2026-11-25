//
//  CloudKitServiceTests.ServerErrorCodes.RetryHints+SignInURL.swift
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
internal import HTTPTypes
internal import Testing

@testable import MistKit

extension CloudKitServiceTests.ServerErrorCodes.RetryHints {
  @Test(
    "fetchWebAuthSignInURL refuses a redirectURL that isn't an https Apple page",
    arguments: [
      "http://idmsa.apple.com/signin",
      "file:///etc/passwd",
      "myapp://callback",
      "https://idmsa.apple.com.example.net/signin",
      "https://evilapple.com/signin",
      "https://example.com/signin",
    ]
  )
  internal func signInURLRefused(redirectURL: String) async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      return
    }
    let service = try Self.service(
      statusCode: 421,
      json: #"{"serverErrorCode":"AUTHENTICATION_REQUIRED","redirectURL":""#
        + redirectURL + #""}"#
    )
    do {
      let url = try await service.fetchWebAuthSignInURL()
      Issue.record("expected fetchWebAuthSignInURL to throw, got \(url)")
    } catch {
      guard case .incompleteResponse = error else {
        Issue.record("expected .incompleteResponse, got \(error)")
        return
      }
    }
  }

  @Test(
    "isAppleSignInURL accepts https apple.com and icloud.com hosts",
    arguments: [
      "https://idmsa.apple.com/IDMSWebAuth/auth",
      "https://apple.com/x",
      "HTTPS://IDMSA.APPLE.COM/signin",
      "https://www.icloud.com/x",
    ]
  )
  internal func appleSignInURLAccepted(string: String) throws {
    let url = try #require(URL(string: string))
    #expect(CloudKitService.isAppleSignInURL(url))
  }
}

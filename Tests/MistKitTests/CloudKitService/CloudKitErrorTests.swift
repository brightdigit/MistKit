//
//  CloudKitErrorTests.swift
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
internal import Testing

@testable import MistKit

#if canImport(FoundationNetworking)
  internal import FoundationNetworking
#endif

@Suite("CloudKitError")
internal struct CloudKitErrorTests {
  /// Raw value of Foundation's `NSURLErrorFailingURLStringErrorKey`. Spelled
  /// literally rather than named because the constant is deprecated on
  /// swift-corelibs-foundation; hard-coding it here also keeps this test
  /// independent of the production constant it exercises.
  private static let failingURLStringKey = "NSErrorFailingURLStringKey"

  @Test(".missingCredentials with .notConfigured describes as not configured")
  internal func missingCredentialsNotConfiguredDescribesAsNotConfigured() throws {
    let error = CloudKitError.missingCredentials(
      database: .public(.prefers(.webAuth)),
      availability: .notConfigured,
      reason: "no API token provided"
    )

    let description = try #require(error.errorDescription)
    #expect(description.contains("public"))
    #expect(description.contains("not configured"))
    #expect(!description.contains("required by preference"))
    #expect(description.contains("no API token provided"))
  }

  @Test(".missingCredentials with .preferenceRequired describes as preference required")
  internal func missingCredentialsPreferenceRequiredDescribesAsPreferenceRequired() throws {
    let error = CloudKitError.missingCredentials(
      database: .public(.requires(.webAuth)),
      availability: .preferenceRequired,
      reason: "web-auth preference required"
    )

    let description = try #require(error.errorDescription)
    #expect(description.contains("public"))
    #expect(description.contains("required by preference but not configured"))
    #expect(description.contains("web-auth preference required"))
  }

  @Test(".networkError reports the failed URL from the string userInfo key")
  internal func networkErrorReportsFailedURLFromStringKey() throws {
    let error = CloudKitError.networkError(
      URLError(
        .timedOut,
        userInfo: [Self.failingURLStringKey: "https://api.apple-cloudkit.com/string"]
      )
    )

    let description = try #require(error.errorDescription)
    #expect(description.contains("Network error occurred"))
    #expect(description.contains("Error code: \(URLError.Code.timedOut.rawValue)"))
    #expect(description.contains("Failed URL: https://api.apple-cloudkit.com/string"))
  }

  @Test(".networkError reports the failed URL from the URL userInfo key")
  internal func networkErrorReportsFailedURLFromURLKey() throws {
    let url = try #require(URL(string: "https://api.apple-cloudkit.com/url"))
    let error = CloudKitError.networkError(
      URLError(.cannotConnectToHost, userInfo: [NSURLErrorFailingURLErrorKey: url])
    )

    let description = try #require(error.errorDescription)
    #expect(description.contains("Error code: \(URLError.Code.cannotConnectToHost.rawValue)"))
    #expect(description.contains("Failed URL: https://api.apple-cloudkit.com/url"))
  }

  @Test(".networkError prefers the URL userInfo key when both are present")
  internal func networkErrorPrefersURLKeyWhenBothPresent() throws {
    let url = try #require(URL(string: "https://api.apple-cloudkit.com/url"))
    let error = CloudKitError.networkError(
      URLError(
        .networkConnectionLost,
        userInfo: [
          NSURLErrorFailingURLErrorKey: url,
          Self.failingURLStringKey: "https://api.apple-cloudkit.com/string",
        ]
      )
    )

    let description = try #require(error.errorDescription)
    #expect(description.contains("Failed URL: https://api.apple-cloudkit.com/url"))
    #expect(!description.contains("https://api.apple-cloudkit.com/string"))
  }

  @Test(".networkError omits the failed URL when neither userInfo key is present")
  internal func networkErrorOmitsFailedURLWhenNoKeysPresent() throws {
    let error = CloudKitError.networkError(URLError(.notConnectedToInternet))

    let description = try #require(error.errorDescription)
    #expect(description.contains("Network error occurred"))
    #expect(description.contains("Error code: \(URLError.Code.notConnectedToInternet.rawValue)"))
    #expect(!description.contains("Failed URL:"))
  }
}

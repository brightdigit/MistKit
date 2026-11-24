//
//  CloudKitService+WebAuthSignIn.swift
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

public import Foundation
internal import MistKitOpenAPI

#if canImport(FoundationNetworking)
  internal import FoundationNetworking
#endif

extension CloudKitService {
  /// Whether `url` is an `https` URL on an `apple.com` or `icloud.com` host.
  ///
  /// The sign-in page is opened in a browser session, so a `redirectURL`
  /// from a tampered or misdirected response (a `file:` or custom-scheme
  /// URL, or another host) is refused rather than returned. Live CloudKit
  /// sends `https://idmsa.apple.com/…`.
  internal static func isAppleSignInURL(_ url: URL) -> Bool {
    guard url.scheme?.lowercased() == "https", let host = url.host?.lowercased() else {
      return false
    }
    return ["apple.com", "icloud.com"].contains { domain in
      host == domain || host.hasSuffix(".\(domain)")
    }
  }

  /// Ask CloudKit for the web sign-in page that issues a web-auth token.
  ///
  /// Sends `users/caller` signed with the API token alone. CloudKit answers
  /// `AUTHENTICATION_REQUIRED` with a `redirectURL`: the Apple sign-in page
  /// for this container. Open it (for example in `ASWebAuthenticationSession`)
  /// and read the `ckWebAuthToken` from the callback the API token's sign-in
  /// settings name.
  ///
  /// Any configured web-auth token is ignored, so the request always asks for
  /// a new sign-in.
  ///
  /// - Returns: The sign-in page.
  /// - Throws: ``CloudKitError/missingCredentials(database:availability:reason:)``
  ///   when the service has no API token;
  ///   ``CloudKitError/incompleteResponse(reason:)`` when CloudKit answered
  ///   without a usable `redirectURL`, or with one that isn't an `https`
  ///   `apple.com` or `icloud.com` page; otherwise the request's error.
  public func fetchWebAuthSignInURL() async throws(CloudKitError) -> URL {
    let database = Database.public(.prefers(.webAuth))
    guard let apiToken = credentials?.apiAuth?.apiToken else {
      throw .missingCredentials(
        database: database,
        availability: .notConfigured,
        reason: "web sign-in needs apiAuth with an API token"
      )
    }
    let failure: CloudKitError
    do {
      try await fetchCallerSignedWithAPIToken(apiToken, context: "fetchWebAuthSignInURL")
      throw CloudKitError.incompleteResponse(
        reason: "users/caller succeeded with only an API token; no sign-in page to open"
      )
    } catch {
      failure = mapToCloudKitError(error, context: "fetchWebAuthSignInURL")
    }
    guard case .authenticationRequired = failure else {
      throw failure
    }
    guard let redirectURL = failure.redirectURL, let url = URL(string: redirectURL) else {
      throw .incompleteResponse(
        reason: "AUTHENTICATION_REQUIRED response had no valid redirectURL"
      )
    }
    guard Self.isAppleSignInURL(url) else {
      throw .incompleteResponse(
        reason: "AUTHENTICATION_REQUIRED redirectURL isn't an https Apple sign-in page"
      )
    }
    return url
  }

  /// Send `users/caller` signed with `apiToken` alone, ignoring any
  /// configured web-auth token.
  ///
  /// With a valid API token CloudKit answers `AUTHENTICATION_REQUIRED`, so
  /// callers inspect the thrown error rather than expect success.
  internal func fetchCallerSignedWithAPIToken(
    _ apiToken: String,
    context: String
  ) async throws(CloudKitError) {
    do {
      let response = try await client(tokenManager: APITokenManager(apiToken: apiToken))
        .getCaller(
          .init(
            path: Operations.getCaller.Input.Path(
              containerIdentifier: containerIdentifier,
              environment: environment,
              database: .public(.prefers(.webAuth))
            )
          )
        )
      _ = try await responseProcessor.processGetCallerResponse(response)
    } catch {
      throw mapToCloudKitError(error, context: context)
    }
  }
}

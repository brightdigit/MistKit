//
//  WebBackendFactory.swift
//  MistDemo
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

#if canImport(Hummingbird)
  internal import Foundation
  internal import MistKit

  /// Factory that returns a `WebBackend` configured with the captured
  /// web-auth token. Injected into `WebServer` so tests can supply a
  /// mock without going through MistKit.
  ///
  /// When server-to-server credentials are present, the produced service
  /// holds both auth flavors and `CloudKitService` picks the right one
  /// per operation based on the request's `database`.
  internal struct WebBackendFactory: Sendable {
    internal let make: @Sendable (_ webAuthToken: String) throws -> any WebBackend

    internal init(
      make:
        @escaping @Sendable (_ webAuthToken: String) throws -> any WebBackend
    ) {
      self.make = make
    }

    /// Production factory: builds a `CloudKitService` for the captured
    /// web-auth token paired with the command's API token. If
    /// `serverToServer` is non-nil, the same service can also satisfy
    /// public-database routes via S2S signing.
    internal static func live(
      apiToken: String,
      containerIdentifier: String,
      environment: MistKit.Environment,
      serverToServer: ServerToServerCredentials? = nil
    ) -> WebBackendFactory {
      WebBackendFactory { webAuthToken in
        let apiAuth = APICredentials(
          apiToken: apiToken,
          webAuthToken: webAuthToken
        )
        let credentials = try Credentials(
          serverToServer: serverToServer,
          apiAuth: apiAuth
        )
        return CloudKitService(
          containerIdentifier: containerIdentifier,
          credentials: credentials,
          environment: environment
        )
      }
    }
  }
#endif

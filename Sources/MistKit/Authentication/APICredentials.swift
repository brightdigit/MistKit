//
//  APICredentials.swift
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

/// API-token credentials, optionally augmented with a web-auth token for
/// user-context routes.
///
/// - `apiToken` alone is sufficient for read access against the public
///   database.
/// - `webAuthToken` is required for any route that operates as a specific
///   user — that includes every user-identity endpoint (`fetchCaller`,
///   `lookupUsersByEmail`, …) and any write/read against the private or
///   shared databases.
public struct APICredentials: Sendable {
  public let apiToken: String
  public let webAuthToken: String?

  public init(apiToken: String, webAuthToken: String? = nil) {
    self.apiToken = apiToken
    self.webAuthToken = webAuthToken
  }
}

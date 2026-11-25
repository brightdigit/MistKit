//
//  CredentialKind.swift
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

/// A kind of credential ``CloudKitService/verifyCredentials()`` checks.
///
/// Each kind maps to the part of `Credentials` that supplies it and the
/// request that checks it.
public enum CredentialKind: String, Sendable, Hashable, CaseIterable {
  /// An API token with a web-auth token (`APICredentials.webAuthToken`):
  /// checked with `users/caller` (``CloudKitService/fetchCaller()``).
  case webAuth

  /// A server-to-server key (`Credentials.serverToServer`): checked by
  /// listing the public database's zones, signed with the key.
  case serverToServer

  /// An API token with no web-auth token: checked with `users/caller`
  /// signed with the API token alone, which CloudKit answers
  /// `AUTHENTICATION_REQUIRED` when the token is valid but nobody has
  /// signed in yet.
  case apiTokenOnly
}

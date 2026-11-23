//
//  CredentialStatus.swift
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

/// What CloudKit said about one credential, from
/// ``CloudKitService/verifyCredentials()``.
///
/// Never carries the credential itself: only whether it worked and, if it
/// didn't, CloudKit's error.
public enum CredentialStatus: Sendable {
  /// CloudKit accepted the credential.
  ///
  /// For ``CredentialKind/apiTokenOnly`` this means the API token is valid
  /// but the user still has to sign in (CloudKit answered
  /// `AUTHENTICATION_REQUIRED`); see
  /// ``CloudKitService/fetchWebAuthSignInURL()``.
  case accepted

  /// CloudKit (or MistKit, before sending) rejected the credential.
  ///
  /// For example `AUTHENTICATION_FAILED` for a wrong API token or
  /// server-to-server key, `AUTHENTICATION_REQUIRED` for an expired web-auth
  /// token, ``CloudKitError/invalidPrivateKey(path:underlying:)`` for a
  /// private key MistKit can't read, or a network error.
  case rejected(CloudKitError)

  /// The service has no credential of this kind, so nothing was sent.
  case notConfigured

  /// Whether CloudKit accepted the credential.
  public var isAccepted: Bool {
    if case .accepted = self {
      return true
    }
    return false
  }

  /// Whether the service has a credential of this kind.
  public var isConfigured: Bool {
    if case .notConfigured = self {
      return false
    }
    return true
  }

  /// The error the credential was rejected with, if it was.
  public var error: CloudKitError? {
    if case .rejected(let error) = self {
      return error
    }
    return nil
  }
}

//
//  DiscoverError.swift
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

public import Foundation

/// Errors that can occur during discover command execution.
public enum DiscoverError: Error, LocalizedError {
  case emailsRequired
  case webAuthRequired

  /// A localized description of the error.
  public var errorDescription: String? {
    switch self {
    case .emailsRequired:
      return
        "No emails provided. Use --discover-emails <list> or pipe "
        + "one address per line to stdin."
    case .webAuthRequired:
      return
        "discover requires API + web-auth credentials. Set "
        + "CLOUDKIT_API_TOKEN and CLOUDKIT_WEB_AUTH_TOKEN, or run "
        + "`mistdemo auth-token` first."
    }
  }

  /// A localized recovery suggestion.
  public var recoverySuggestion: String? {
    switch self {
    case .emailsRequired:
      return
        "Pass --discover-emails alice@example.com,bob@example.com, "
        + "or pipe addresses to stdin with --stdin."
    case .webAuthRequired:
      return
        "User-identity routes (lookupUsersByEmail) are pinned to "
        + "CloudKit's public DB and require web-auth."
    }
  }
}

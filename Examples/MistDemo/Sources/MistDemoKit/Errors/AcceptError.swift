//
//  AcceptError.swift
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

/// Errors that can occur during accept command execution.
public enum AcceptError: Error, LocalizedError {
  case shortGUIDRequired
  case webAuthRequired
  case operationFailed(String)

  /// A localized description of the error.
  public var errorDescription: String? {
    switch self {
    case .shortGUIDRequired:
      return
        "No short GUID provided. Use --short-guid <guid> or "
        + "--share-url <url>."
    case .webAuthRequired:
      return
        "accept requires API + web-auth credentials. Set "
        + "CLOUDKIT_API_TOKEN and CLOUDKIT_WEB_AUTH_TOKEN, or run "
        + "`mistdemo auth-token` first."
    case .operationFailed(let reason):
      return "Accept operation failed: \(reason)"
    }
  }

  /// A localized recovery suggestion.
  public var recoverySuggestion: String? {
    switch self {
    case .shortGUIDRequired:
      return
        "Pass --short-guid abc123, or --share-url "
        + "https://www.icloud.com/share/abc123."
    case .webAuthRequired:
      return
        "records/accept is pinned to CloudKit's public DB and "
        + "requires web-auth."
    case .operationFailed:
      return nil
    }
  }
}

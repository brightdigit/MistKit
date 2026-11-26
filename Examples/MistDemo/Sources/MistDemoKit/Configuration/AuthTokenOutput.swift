//
//  AuthTokenOutput.swift
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

internal import Foundation

/// How `auth-token` / `auth-tokens` present the captured token(s)
/// (`--output` / `CLOUDKIT_OUTPUT`).
public enum AuthTokenOutput: String, Sendable, CaseIterable {
  /// Human-readable progress plus the token(s) on stdout (the historical output).
  case text
  /// Only `KEY=value` lines on stdout; every prompt and progress line goes to
  /// stderr, so the output can be parsed by scripts such as
  /// `Scripts/refresh-web-auth-tokens.sh`.
  case env

  // MARK: Lifecycle

  /// Parses an `--output` value case-insensitively.
  /// - Throws: ``ConfigurationError/invalidOutput(_:allowed:)`` for unknown values.
  internal init(parsing value: String) throws {
    guard let output = Self(rawValue: value.lowercased()) else {
      throw ConfigurationError.invalidOutput(
        value,
        allowed: Self.allCases.map(\.rawValue)
      )
    }
    self = output
  }

  // MARK: Internal

  /// Formats captured credentials as dotenv `KEY=value` lines.
  ///
  /// Values are emitted unquoted, one per line; `shareeWebAuthToken` and
  /// `shareeEmail` are omitted when `nil` or empty.
  internal static func envLines(
    webAuthToken: String,
    shareeWebAuthToken: String? = nil,
    shareeEmail: String? = nil
  ) -> [String] {
    var lines = ["CLOUDKIT_WEB_AUTH_TOKEN=\(webAuthToken)"]
    if let shareeWebAuthToken, !shareeWebAuthToken.isEmpty {
      lines.append("CLOUDKIT_SHAREE_WEB_AUTH_TOKEN=\(shareeWebAuthToken)")
    }
    if let shareeEmail, !shareeEmail.isEmpty {
      lines.append("CLOUDKIT_SHAREE_EMAIL=\(shareeEmail)")
    }
    return lines
  }

  /// Writes a progress/prompt message: stdout for ``text``, stderr for ``env``
  /// (so stdout carries only `KEY=value` lines).
  internal func progress(_ message: String) {
    switch self {
    case .text:
      print(message)
    case .env:
      FileHandle.standardError.write(Data((message + "\n").utf8))
    }
  }
}

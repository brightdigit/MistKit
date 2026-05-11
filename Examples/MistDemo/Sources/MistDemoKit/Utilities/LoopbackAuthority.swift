//
//  LoopbackAuthority.swift
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

/// Helper for validating that an HTTP `:authority` value identifies a
/// loopback host.
///
/// Used by the auth-token server to reject requests that target the
/// loopback callback from non-loopback hosts (e.g. forwarded ports or
/// remote browsers proxying into the process).
internal enum LoopbackAuthority {
  /// Hosts treated as loopback. Bracketed form is used for IPv6 because
  /// that is the canonical authority shape.
  internal static let allowed: Set<String> = [
    "localhost",
    "127.0.0.1",
    "[::1]",
  ]

  /// Returns `true` when the authority's host (port stripped) matches one
  /// of the recognized loopback hosts.
  ///
  /// - Parameter authority: An HTTP `:authority` value such as
  ///   `"127.0.0.1:8080"`, `"localhost"`, or `"[::1]:8080"`.
  /// - Returns: `true` if the authority is loopback; `false` otherwise.
  internal static func isLoopback(_ authority: String) -> Bool {
    guard let host = host(in: authority) else {
      return false
    }
    return allowed.contains(host)
  }

  /// Returns the host portion of `authority`, stripping a trailing port.
  /// Returns `nil` for malformed bracketed IPv6 authorities.
  private static func host(in authority: String) -> String? {
    if authority.hasPrefix("[") {
      return bracketedHost(in: authority)
    }
    let host = authority.split(separator: ":", maxSplits: 1).first
    return host.map(String.init) ?? authority
  }

  private static func bracketedHost(in authority: String) -> String? {
    guard let endBracket = authority.firstIndex(of: "]") else {
      return nil
    }
    let host = String(authority[authority.startIndex...endBracket])
    let afterBracket = authority[authority.index(after: endBracket)...]
    if afterBracket.isEmpty {
      return host
    }
    guard afterBracket.hasPrefix(":") else {
      return nil
    }
    return host
  }
}

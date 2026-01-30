//
//  StandardNamingStyle.swift
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

import Foundation

/// Common naming styles for configuration keys
public enum StandardNamingStyle: NamingStyle, Sendable {
  /// Dot-separated lowercase (e.g., "cloudkit.container_id")
  case dotSeparated

  /// Screaming snake case with prefix (e.g., "BUSHEL_CLOUDKIT_CONTAINER_ID")
  case screamingSnakeCase(prefix: String?)

  public func transform(_ base: String) -> String {
    switch self {
    case .dotSeparated:
      return base

    case .screamingSnakeCase(let prefix):
      let snakeCase = base.uppercased().replacingOccurrences(of: ".", with: "_")
      if let prefix = prefix {
        return "\(prefix)_\(snakeCase)"
      }
      return snakeCase
    }
  }
}
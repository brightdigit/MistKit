//
//  PrivateKeyMaterial.swift
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

internal import Foundation

/// Source of a server-to-server private key — either inline PEM or a path to a
/// `.pem` file on disk.
///
/// Used by `ServerToServerCredentials` to defer reading the private key until
/// the credentials are actually consumed by `CloudKitService`. Inline PEM may
/// contain literal `\n` escape sequences (common when stored in environment
/// variables); `loadPEM()` normalizes them to real newlines.
public enum PrivateKeyMaterial: Sendable {
  case raw(String)
  case file(path: String)

  /// Resolve the PEM text for this material.
  ///
  /// - Throws: Any error from the underlying file read when `.file(path:)` is
  ///   used (e.g. file not found, permission denied).
  public func loadPEM() throws -> String {
    switch self {
    case .raw(let pem):
      return pem.replacingOccurrences(of: "\\n", with: "\n")
    case .file(let path):
      return try String(contentsOfFile: path, encoding: .utf8)
    }
  }
}

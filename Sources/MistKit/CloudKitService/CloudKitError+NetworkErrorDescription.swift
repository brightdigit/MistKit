//
//  CloudKitError+NetworkErrorDescription.swift
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

#if canImport(FoundationNetworking)
  internal import FoundationNetworking
#endif

extension CloudKitError {
  /// Raw value of Foundation's `NSURLErrorFailingURLStringErrorKey`, spelled
  /// literally because that constant is itself deprecated on
  /// swift-corelibs-foundation — naming it would only relocate the warning.
  /// Verified identical on Darwin Foundation and corelibs-foundation.
  private static let failingURLStringKey = "NSErrorFailingURLStringKey"

  /// Renders a `URLError` into a human-readable description.
  ///
  /// Split out of `CloudKitError+ErrorDescription.swift` to keep that file
  /// within the file-length limit.
  internal static func networkErrorDescription(_ error: URLError) -> String {
    var message = "Network error occurred"
    message += "\nError code: \(error.code.rawValue)"
    if let url = Self.failingURLString(for: error) {
      message += "\nFailed URL: \(url)"
    }
    message += "\nDescription: \(error.localizedDescription)"
    return message
  }

  /// The URL a `URLError` failed on, rendered as a string.
  ///
  /// `failingURL` reads `NSURLErrorFailingURLErrorKey`; the `failureURLString`
  /// it deprecates read the *distinct* `NSErrorFailingURLStringKey`. An error
  /// may carry either key, so prefer the typed `URL` and fall back to the
  /// string key rather than dropping the URL from the description.
  private static func failingURLString(for error: URLError) -> String? {
    if let failingURL = error.failingURL {
      return failingURL.absoluteString
    }
    return error.errorUserInfo[Self.failingURLStringKey] as? String
  }
}

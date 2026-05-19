//
//  NetworkErrorReason.swift
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

public import Foundation

#if canImport(FoundationNetworking)
  internal import FoundationNetworking
#endif

/// Specific reasons for network errors during authentication
public enum NetworkErrorReason: Sendable {
  /// Request timed out
  case timeout

  /// Network connection was lost
  case connectionLost

  /// Device is not connected to the internet
  case notConnectedToInternet

  /// A URL-level error occurred
  case urlError(URLError)

  /// Any other network error
  case other(any Error)

  /// A human-readable description of the network error reason
  public var description: String {
    switch self {
    case .timeout:
      return "Request timed out"
    case .connectionLost:
      return "Network connection was lost"
    case .notConnectedToInternet:
      return "Not connected to the internet"
    case .urlError(let error):
      return "URL error: \(error.localizedDescription)"
    case .other(let error):
      return error.localizedDescription
    }
  }
}

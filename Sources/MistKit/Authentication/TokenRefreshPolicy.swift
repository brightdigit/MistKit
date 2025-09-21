//
//  TokenRefreshPolicy.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import Foundation

/// Defines when and how tokens should be refreshed
public enum TokenRefreshPolicy: Sendable, Equatable {
  /// Refresh tokens only when they expire
  case onExpiry

  /// Refresh tokens at regular intervals
  case periodic(TimeInterval)

  /// Manual refresh only - no automatic refresh
  case manual

  /// Returns true if this policy supports automatic refresh
  public var supportsAutomaticRefresh: Bool {
    switch self {
    case .onExpiry, .periodic:
      return true
    case .manual:
      return false
    }
  }

  /// Returns the refresh interval if applicable
  public var refreshInterval: TimeInterval? {
    switch self {
    case .onExpiry, .manual:
      return nil
    case .periodic(let interval):
      return interval
    }
  }
}

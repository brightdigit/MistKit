//
//  RetryPolicy.swift
//  PackageDSLKit
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

/// Configuration for retry behavior during authentication operations
public struct RetryPolicy: Sendable, Equatable {
  /// Maximum number of retry attempts
  public let maxAttempts: Int

  /// Base delay between retries (will be multiplied by attempt number for exponential backoff)
  public let baseDelay: TimeInterval

  /// Maximum delay between retries (caps exponential backoff)
  public let maxDelay: TimeInterval

  /// Creates a new retry policy
  /// - Parameters:
  ///   - maxAttempts: Maximum number of retry attempts (default: 3)
  ///   - baseDelay: Base delay in seconds (default: 1.0)
  ///   - maxDelay: Maximum delay in seconds (default: 60.0)
  public init(maxAttempts: Int = 3, baseDelay: TimeInterval = 1.0, maxDelay: TimeInterval = 60.0) {
    self.maxAttempts = maxAttempts
    self.baseDelay = baseDelay
    self.maxDelay = maxDelay
  }

  /// Calculates delay for a specific attempt using exponential backoff
  /// - Parameter attempt: The attempt number (1-based)
  /// - Returns: Delay in seconds for this attempt
  public func delay(for attempt: Int) -> TimeInterval {
    let exponentialDelay = baseDelay * pow(2.0, Double(attempt - 1))
    return min(exponentialDelay, maxDelay)
  }

  /// Default retry policy for authentication operations
  public static let `default` = RetryPolicy()

  /// No retry policy (single attempt only)
  public static let none = RetryPolicy(maxAttempts: 1)

  /// Aggressive retry policy for critical operations
  public static let aggressive = RetryPolicy(maxAttempts: 5, baseDelay: 0.5, maxDelay: 30.0)
}

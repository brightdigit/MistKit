//
//  QueryValidation.swift
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

/// The result of checking a ``QueryDescriptor`` against a schema.
public struct QueryValidation: Hashable, Sendable {
  /// Every issue, in query order: record type and limit, conditions, sorts,
  /// desired keys.
  public var issues: [QueryValidationIssue]

  /// Whether the query can be sent: no issue blocks it.
  public var isValid: Bool {
    !issues.contains(where: \.isBlocking)
  }

  /// Creates a result.
  /// - Parameter issues: The issues found, in query order.
  public init(issues: [QueryValidationIssue] = []) {
    self.issues = issues
  }

  /// The issues about one part of the query.
  /// - Parameter target: The part of the query.
  /// - Returns: Its issues, in order.
  public func issues(for target: QueryValidationIssue.Target) -> [QueryValidationIssue] {
    issues.filter { $0.target == target }
  }
}

//
//  QueryDescriptor.Comparator+FilterComparator.swift
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

extension QueryDescriptor.Comparator {
  /// Every comparator that takes no operand, in ``FilterComparator`` order.
  private static let withoutOperand: [Self] = [
    .equals, .notEquals, .lessThan, .lessThanOrEquals, .greaterThan, .greaterThanOrEquals,
    .containsAllTokens, .containsAnyTokens, .in, .notIn, .listContains, .notListContains,
    .beginsWith, .notBeginsWith, .listMemberBeginsWith, .notListMemberBeginsWith,
  ]

  /// The CloudKit comparator this sends.
  public var filterComparator: FilterComparator {
    switch self {
    case .equals: .equals
    case .notEquals: .notEquals
    case .lessThan: .lessThan
    case .lessThanOrEquals: .lessThanOrEquals
    case .greaterThan: .greaterThan
    case .greaterThanOrEquals: .greaterThanOrEquals
    case .beginsWith: .beginsWith
    case .notBeginsWith: .notBeginsWith
    case .containsAllTokens: .containsAllTokens
    case .containsAnyTokens: .containsAnyTokens
    case .in: .in
    case .notIn: .notIn
    case .listContains: .listContains
    case .notListContains: .notListContains
    case .listMemberBeginsWith: .listMemberBeginsWith
    case .notListMemberBeginsWith: .notListMemberBeginsWith
    case .near: .near
    }
  }

  /// Whether the value is a list of the field's type: `IN` and `NOT_IN`.
  public var takesList: Bool {
    self == .in || self == .notIn
  }

  /// Creates the comparator for a CloudKit comparator that takes no operand.
  ///
  /// `nil` for ``FilterComparator/near``, which needs a distance; use
  /// ``near(meters:)``.
  public init?(_ comparator: FilterComparator) {
    guard let match = Self.withoutOperand.first(where: { $0.filterComparator == comparator })
    else {
      return nil
    }
    self = match
  }
}

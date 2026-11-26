//
//  FilterComparator.swift
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

/// A CloudKit Web Services query filter comparator, by its wire name.
///
/// Use ``SchemaFieldType/allowedComparators`` to find which comparators a
/// field's type accepts, and ``requiresSortableIndex`` to know which also need
/// a `SORTABLE` index. Build filters with ``QueryFilter``'s factories.
public enum FilterComparator: String, Sendable, Hashable, CaseIterable {
  case equals = "EQUALS"
  case notEquals = "NOT_EQUALS"
  case lessThan = "LESS_THAN"
  case lessThanOrEquals = "LESS_THAN_OR_EQUALS"
  case greaterThan = "GREATER_THAN"
  case greaterThanOrEquals = "GREATER_THAN_OR_EQUALS"
  case near = "NEAR"
  case containsAllTokens = "CONTAINS_ALL_TOKENS"
  case containsAnyTokens = "CONTAINS_ANY_TOKENS"
  // swiftlint:disable:next identifier_name
  case `in` = "IN"
  case notIn = "NOT_IN"
  case listContains = "LIST_CONTAINS"
  case notListContains = "NOT_LIST_CONTAINS"
  case beginsWith = "BEGINS_WITH"
  case notBeginsWith = "NOT_BEGINS_WITH"
  case listMemberBeginsWith = "LIST_MEMBER_BEGINS_WITH"
  case notListMemberBeginsWith = "NOT_LIST_MEMBER_BEGINS_WITH"

  /// Whether the field also needs a `SORTABLE` index.
  ///
  /// CloudKit rejects range comparisons (`<`, `≤`, `>`, `≥`) on a field
  /// that's `QUERYABLE` but not `SORTABLE`; every comparator needs
  /// `QUERYABLE` (the token comparators need `SEARCHABLE` instead).
  public var requiresSortableIndex: Bool {
    switch self {
    case .lessThan, .lessThanOrEquals, .greaterThan, .greaterThanOrEquals:
      return true
    default:
      return false
    }
  }

  /// Whether the field needs a `SEARCHABLE` (full-text) index instead of a
  /// `QUERYABLE` one.
  public var requiresSearchableIndex: Bool {
    self == .containsAllTokens || self == .containsAnyTokens
  }
}

extension SchemaFieldType {
  private static let ordered: [FilterComparator] = [
    .equals, .notEquals, .lessThan, .lessThanOrEquals, .greaterThan, .greaterThanOrEquals,
  ]

  /// The comparators CloudKit accepts in a filter on a field of this type.
  ///
  /// Empty for `ENCRYPTED` fields (CloudKit doesn't index them), `BYTES` and
  /// `ASSET`. Lists take the list-member comparators; `LIST<STRING>` adds the
  /// list-member prefix comparators. The index each comparator needs is on
  /// ``FilterComparator``.
  public var allowedComparators: [FilterComparator] {
    guard !isEncrypted else {
      return []
    }
    if isList {
      let membership: [FilterComparator] = [.listContains, .notListContains]
      return primitive == .string
        ? membership + [.listMemberBeginsWith, .notListMemberBeginsWith] : membership
    }
    switch primitive {
    case .string:
      return Self.ordered + [
        .beginsWith, .notBeginsWith, .in, .notIn, .containsAllTokens, .containsAnyTokens,
      ]
    case .int64, .double, .timestamp, .number:
      return Self.ordered + [.in, .notIn]
    case .reference:
      return [.equals, .notEquals, .in, .notIn]
    case .location:
      return [.near]
    case .bytes, .asset:
      return []
    }
  }
}

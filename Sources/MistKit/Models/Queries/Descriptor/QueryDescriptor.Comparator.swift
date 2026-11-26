//
//  QueryDescriptor.Comparator.swift
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

extension QueryDescriptor {
  /// How a condition compares its field with its value.
  ///
  /// One case per CloudKit ``FilterComparator``, with the radius
  /// ``near(meters:)`` needs. ``filterComparator`` gives the CloudKit
  /// comparator, whose index rules are on ``FilterComparator``; which
  /// comparators a field type accepts is ``SchemaFieldType/allowedComparators``.
  public enum Comparator: Hashable, Codable, Sendable {
    /// `EQUALS`
    case equals
    /// `NOT_EQUALS`
    case notEquals
    /// `LESS_THAN`
    case lessThan
    /// `LESS_THAN_OR_EQUALS`
    case lessThanOrEquals
    /// `GREATER_THAN`
    case greaterThan
    /// `GREATER_THAN_OR_EQUALS`
    case greaterThanOrEquals
    /// `BEGINS_WITH`, on a `STRING` field.
    case beginsWith
    /// `NOT_BEGINS_WITH`, on a `STRING` field.
    case notBeginsWith
    /// `CONTAINS_ALL_TOKENS`, on a `SEARCHABLE` `STRING` field.
    case containsAllTokens
    /// `CONTAINS_ANY_TOKENS`, on a `SEARCHABLE` `STRING` field.
    case containsAnyTokens
    // swiftlint:disable identifier_name
    /// `IN`: the field equals one of the values in a list.
    case `in`
    // swiftlint:enable identifier_name
    /// `NOT_IN`: the field equals none of the values in a list.
    case notIn
    /// `LIST_CONTAINS`: a list field contains the value.
    case listContains
    /// `NOT_LIST_CONTAINS`: a list field doesn't contain the value.
    case notListContains
    /// `LIST_MEMBER_BEGINS_WITH`, on a `LIST<STRING>` field.
    case listMemberBeginsWith
    /// `NOT_LIST_MEMBER_BEGINS_WITH`, on a `LIST<STRING>` field.
    case notListMemberBeginsWith
    /// `NEAR`: a `LOCATION` field lies within `meters` of the value.
    case near(meters: Double)
  }
}

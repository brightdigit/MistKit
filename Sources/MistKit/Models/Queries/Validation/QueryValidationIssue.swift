//
//  QueryValidationIssue.swift
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

/// A problem with a ``QueryDescriptor``, found by checking it against a
/// schema before it's sent.
///
/// Each case carries what an app needs to word the problem itself; use
/// ``target`` to point at the part of the query it's about.
public enum QueryValidationIssue: Hashable, Sendable {
  /// The schema has no record type of this name.
  case unknownRecordType(String)
  /// The record type has no field of this name, in a condition or sort.
  case unknownField(String, target: Target)
  /// A desired key the record type doesn't have; it comes back empty, so this
  /// doesn't block the query.
  case unknownDesiredKey(String, index: Int)
  /// A filter on a field without a `QUERYABLE` index.
  case notQueryable(String, condition: Int)
  /// A token filter on a field without a `SEARCHABLE` index.
  case notSearchable(String, condition: Int)
  /// A sort, or a range filter (`<`, `≤`, `>`, `≥`), on a field without a
  /// `SORTABLE` index.
  case notSortable(String, target: Target)
  /// The comparator doesn't apply to the field's type
  /// (``SchemaFieldType/allowedComparators``).
  case unsupportedComparator(FilterComparator, field: SchemaField, condition: Int)
  /// The value's type doesn't fit the field and comparator.
  case valueMismatch(field: SchemaField, valueType: FieldType, condition: Int)
  /// The limit is outside one page.
  case limitOutOfRange(Int, allowed: ClosedRange<Int>)
  /// The schema was inferred from records, so indexes can't be checked; this
  /// doesn't block the query, but CloudKit may still reject it.
  case indexesUnknown
}

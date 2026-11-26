//
//  QueryDescriptor+Validation.swift
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
  /// The limits a page of results may have.
  public static let allowedLimits = 1...CloudKitService.maxRecordsPerRequest

  /// Checks the query against a schema before it's sent.
  ///
  /// CloudKit rejects filters on fields that aren't `QUERYABLE` (token filters:
  /// `SEARCHABLE`), sorts and range filters on fields that aren't `SORTABLE`,
  /// comparators a field's type doesn't take and values of the wrong type.
  /// Fields are looked up with ``SchemaRecordType/queryField(named:)``, so the
  /// implicit system fields count.
  /// - Parameters:
  ///   - schema: The schema to check against.
  ///   - checksIndexes: Whether the schema's indexes and field list are
  ///     authoritative. Pass `false` for a schema inferred from records, which
  ///     has neither; the result then carries
  ///     ``QueryValidationIssue/indexesUnknown`` and skips those checks.
  /// - Returns: The issues found.
  public func validate(
    against schema: CloudKitSchema,
    checksIndexes: Bool = true
  ) -> QueryValidation {
    guard let type = schema.recordType(named: recordType) else {
      return QueryValidation(issues: [.unknownRecordType(recordType)])
    }
    var issues: [QueryValidationIssue] = checksIndexes ? [] : [.indexesUnknown]
    if !Self.allowedLimits.contains(limit) {
      issues.append(.limitOutOfRange(limit, allowed: Self.allowedLimits))
    }
    let validator = QueryConditionValidator(recordType: type, checksIndexes: checksIndexes)
    for (index, condition) in conditions.enumerated() {
      issues += validator.issues(for: condition, at: index)
    }
    if checksIndexes {
      issues += sortIssues(in: type) + desiredKeyIssues(in: type)
    }
    return QueryValidation(issues: issues)
  }

  /// Checks the query against a schema inferred from records, which has no
  /// index information.
  /// - Parameter inferred: The inferred schema.
  /// - Returns: The issues found, starting with
  ///   ``QueryValidationIssue/indexesUnknown``.
  public func validate(against inferred: InferredSchema) -> QueryValidation {
    validate(against: inferred.schema, checksIndexes: false)
  }

  private func sortIssues(in type: SchemaRecordType) -> [QueryValidationIssue] {
    sorts.enumerated().compactMap { index, sort in
      guard let field = type.queryField(named: sort.fieldName) else {
        return .unknownField(sort.fieldName, target: .sort(index))
      }
      return field.isSortable ? nil : .notSortable(sort.fieldName, target: .sort(index))
    }
  }

  private func desiredKeyIssues(in type: SchemaRecordType) -> [QueryValidationIssue] {
    (desiredKeys ?? []).enumerated().compactMap { index, name in
      type.queryField(named: name) == nil ? .unknownDesiredKey(name, index: index) : nil
    }
  }
}

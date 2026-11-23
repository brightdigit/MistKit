//
//  InferredSchema.swift
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

/// A schema worked out from records, such as the results of a query, and the
/// guesses it made.
///
/// Every field any record of a type sets becomes a field of that type, sorted
/// by name, with the type of its first value (lists carry their element type
/// even when empty). Nothing is `QUERYABLE`, `SORTABLE` or `SEARCHABLE` and
/// there are no grants or roles, since records don't say.
public struct InferredSchema: Sendable, Hashable {
  /// The schema: record types with fields, no indexes or grants.
  public var schema: CloudKitSchema
  /// What the inference had to guess.
  public var notices: [SchemaNotice]

  /// Creates an inferred schema from already-worked-out parts.
  public init(schema: CloudKitSchema, notices: [SchemaNotice] = []) {
    self.schema = schema
    self.notices = notices
  }

  /// Infers record types from records.
  ///
  /// - Parameters:
  ///   - records: The records to look at.
  ///   - recordTypes: The record types to infer, in order; a name given twice
  ///     counts once. A type with no records gets only a
  ///     ``SchemaNotice/noRecords(recordType:)`` notice. `nil` infers every
  ///     type the records have, in the order first seen.
  public init(inferringFrom records: [RecordInfo], recordTypes: [String]? = nil) {
    let names = Self.uniqued(recordTypes ?? records.compactMap(\.recordType))
    var notices: [SchemaNotice] = []
    let types = names.map { name in
      let (recordType, typeNotices) = Self.recordType(
        named: name,
        from: records.filter { $0.recordType == name }
      )
      notices += typeNotices
      return recordType
    }
    self.init(schema: CloudKitSchema(recordTypes: types), notices: notices)
  }

  private static func recordType(
    named name: String,
    from records: [RecordInfo]
  ) -> (SchemaRecordType, [SchemaNotice]) {
    guard !records.isEmpty else {
      return (SchemaRecordType(name: name), [.noRecords(recordType: name)])
    }
    var seen: [String: [FieldType]] = [:]
    for record in records {
      for (field, value) in record.fields {
        let type = value.fieldType
        if seen[field]?.contains(type) != true {
          seen[field, default: []].append(type)
        }
      }
    }
    var notices: [SchemaNotice] = []
    let fields = seen.keys.sorted().compactMap { field -> SchemaField? in
      guard let types = seen[field], let first = types.first else {
        return nil
      }
      if types.count > 1 {
        notices.append(.conflictingTypes(recordType: name, field: field, types: types))
      }
      return SchemaField(name: field, type: SchemaFieldType(first))
    }
    return (SchemaRecordType(name: name, fields: fields), notices)
  }

  private static func uniqued(_ names: [String]) -> [String] {
    var seen: Set<String> = []
    return names.filter { seen.insert($0).inserted }
  }
}

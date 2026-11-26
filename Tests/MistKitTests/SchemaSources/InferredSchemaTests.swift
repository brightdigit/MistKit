//
//  InferredSchemaTests.swift
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
internal import Testing

@testable import MistKit

@Suite("Inferred schema")
internal struct InferredSchemaTests {
  private static func note(_ name: String, _ fields: [String: FieldValue]) -> RecordInfo {
    RecordInfo(recordName: name, recordType: "Note", fields: fields)
  }

  @Test("conflicting value types keep the first one seen, and say so")
  internal func conflictingTypes() {
    let inferred = InferredSchema(
      inferringFrom: [
        Self.note("a", ["size": .int64(.value(1))]),
        Self.note("b", ["size": .string(.value("big"))]),
        Self.note("c", ["size": .int64(.value(2))]),
      ],
      recordTypes: ["Note"]
    )
    #expect(
      inferred.schema.recordType(named: "Note")?.fields
        == [SchemaField(name: "size", type: SchemaFieldType(.int64))]
    )
    #expect(
      inferred.notices == [
        .conflictingTypes(recordType: "Note", field: "size", types: [.int64, .string])
      ]
    )
  }

  @Test("a list and a single value of one kind conflict")
  internal func listAndScalar() {
    let inferred = InferredSchema(
      inferringFrom: [
        Self.note("a", ["tags": .string(.list([]))]),
        Self.note("b", ["tags": .string(.value("x"))]),
      ]
    )
    #expect(
      inferred.schema.recordType(named: "Note")?.field(named: "tags")?.resolvedType
        == .list(.string)
    )
    #expect(
      inferred.notices == [
        .conflictingTypes(recordType: "Note", field: "tags", types: [.list(.string), .string])
      ]
    )
  }

  @Test("without record types, every type the records have, in the order first seen")
  internal func everyType() {
    let records = [
      RecordInfo(recordName: "1", recordType: "B", fields: ["x": .double(.value(1))]),
      RecordInfo(recordName: "2", recordType: "A", fields: [:]),
      RecordInfo(recordName: "3", recordType: "B", fields: ["y": .bytes(.value(Data()))]),
      RecordInfo(recordName: "4", recordType: nil, fields: ["z": .int64(.value(1))]),
    ]
    let schema = InferredSchema(inferringFrom: records).schema
    #expect(schema.recordTypes.map(\.name) == ["B", "A"])
    #expect(schema.recordType(named: "B")?.fields.map(\.name) == ["x", "y"])
    #expect(schema.recordType(named: "A")?.fields.isEmpty == true)
  }

  @Test("records of other types are ignored; named types without records are noted")
  internal func namedTypes() {
    let inferred = InferredSchema(
      inferringFrom: [
        RecordInfo(recordName: "1", recordType: "Other", fields: ["x": .double(.value(1))])
      ],
      recordTypes: ["Ghost", "Ghost"]
    )
    #expect(inferred.schema.recordTypes == [SchemaRecordType(name: "Ghost")])
    #expect(inferred.notices == [.noRecords(recordType: "Ghost")])
  }

  @Test("nothing inferred is indexed, and the system fields are implicit")
  internal func unindexed() {
    let inferred = InferredSchema(
      inferringFrom: [Self.note("a", ["title": .string(.value("t"))])]
    )
    let note = inferred.schema.recordType(named: "Note")
    let fields = note?.fieldsIncludingImplicit ?? []
    #expect(fields.count == 7)
    #expect(fields.allSatisfy { !$0.isQueryable && !$0.isSortable && !$0.isSearchable })
  }
}

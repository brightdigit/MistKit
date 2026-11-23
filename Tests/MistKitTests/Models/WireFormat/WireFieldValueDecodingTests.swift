//
//  WireFieldValueDecodingTests.swift
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

/// Decoding tagged and untagged field dictionaries (MistKit #503).
@Suite("Wire field value decoding")
internal struct WireFieldValueDecodingTests {
  private static func decode(
    _ json: String,
    types: [String: SchemaFieldType] = [:]
  ) throws -> WireFieldValue? {
    let decoder = JSONDecoder()
    decoder.userInfo[.cloudKitFieldTypes] = types
    let fields = try decoder.decode(
      [String: WireFieldValue].self,
      from: Data(#"{"f":\#(json)}"#.utf8)
    )
    return fields["f"]
  }

  @Test(
    "untagged values are typed by their JSON shape",
    arguments: [
      (#"{"value":"x"}"#, FieldValue.string(.value("x"))),
      (#"{"value":5}"#, .int64(.value(5))),
      (#"{"value":0.125}"#, .double(.value(0.125))),
      (#"{"value":{"recordName":"r"}}"#, .reference(.value(Reference(recordName: "r")))),
      (
        #"{"value":{"latitude":1,"longitude":2}}"#,
        .location(.value(Location(latitude: 1, longitude: 2)))
      ),
      (#"{"value":{"fileChecksum":"c"}}"#, .asset(.value(Asset(fileChecksum: "c")))),
      (#"{"value":["a","b"]}"#, .string(.list(["a", "b"]))),
      (#"{"value":[1,2]}"#, .int64(.list([1, 2]))),
      (#"{"value":5.0}"#, .int64(.value(5))),
    ]
  )
  internal func untagged(json: String, expected: FieldValue) throws {
    let field = try #require(try Self.decode(json))
    #expect(field.value == expected)
    #expect(field.typeTagging == .whenRequired)
  }

  @Test(
    "a schema type types an untagged value",
    arguments: [
      (
        #"{"value":1000}"#, SchemaFieldType(.timestamp),
        FieldValue.date(.value(Date(timeIntervalSince1970: 1)))
      ),
      (#"{"value":"AP8="}"#, SchemaFieldType(.bytes), .bytes(.value(Data([0x00, 0xFF])))),
      (#"{"value":5}"#, SchemaFieldType(.double), .double(.value(5))),
      (#"{"value":[]}"#, SchemaFieldType(.int64, isList: true), .int64(.list([]))),
      (#"{"value":5}"#, SchemaFieldType(.number(preferredAs: .double)), .double(.value(5))),
      (#"{"value":5}"#, SchemaFieldType(.number(preferredAs: nil)), .int64(.value(5))),
    ]
  )
  internal func schemaTyped(json: String, type: SchemaFieldType, expected: FieldValue) throws {
    let field = try #require(try Self.decode(json, types: ["f": type]))
    #expect(field.value == expected)
    #expect(field.typeTagging == .whenRequired)
  }

  @Test("a value's own type wins over the schema's")
  internal func tagWins() throws {
    let field = try #require(
      try Self.decode(#"{"value":5,"type":"INT64"}"#, types: ["f": SchemaFieldType(.double)])
    )
    #expect(field.value == .int64(.value(5)))
    #expect(field.typeTagging == .always)
  }

  @Test(
    "a value that contradicts its type throws at the field without trapping",
    arguments: [
      (#"{"value":"x","type":"TIMESTAMP"}"#, [String: SchemaFieldType]()),
      (#"{"value":"x"}"#, ["f": SchemaFieldType(.int64)]),
    ]
  )
  internal func contradiction(json: String, types: [String: SchemaFieldType]) throws {
    let error = try #require(throws: DecodingError.self) {
      try Self.decode(json, types: types)
    }
    guard case .dataCorrupted(let context) = error else {
      Issue.record("Expected dataCorrupted, got \(error)")
      return
    }
    #expect(context.codingPath.map(\.stringValue) == ["f"])
    #expect(context.underlyingError is ConversionError)
  }

  @Test("a contradiction inside an array of records names the record and field")
  internal func contradictionPath() throws {
    let json =
      #"[{"recordName":"a"},"#
      + #"{"recordName":"b","fields":{"n":{"value":"x","type":"INT64"}}}]"#
    let error = try #require(throws: DecodingError.self) {
      try JSONDecoder().decode(WireRecordDocument.self, from: Data(json.utf8))
    }
    guard case .dataCorrupted(let context) = error else {
      Issue.record("Expected dataCorrupted, got \(error)")
      return
    }
    #expect(context.codingPath.first?.intValue == 1)
    #expect(context.codingPath.map(\.stringValue).suffix(2) == ["fields", "n"])
  }

  @Test("an unknown zoneType throws at the record")
  internal func unknownZoneType() throws {
    let json = #"[{"recordName":"a","zoneID":{"zoneName":"z","zoneType":"NOPE"}}]"#
    let error = try #require(throws: DecodingError.self) {
      try JSONDecoder().decode(WireRecordDocument.self, from: Data(json.utf8))
    }
    guard case .dataCorrupted(let context) = error else {
      Issue.record("Expected dataCorrupted, got \(error)")
      return
    }
    #expect(context.codingPath.map(\.intValue) == [0])
    #expect(context.underlyingError as? ConversionError == .unrecognizedZoneType("NOPE"))
  }

  @Test("an empty list is typed by its tag or schema type")
  internal func emptyList() throws {
    let tagged = try #require(try Self.decode(#"{"value":[],"type":"STRING_LIST"}"#))
    #expect(tagged.value == .string(.list([])))
    #expect(tagged.typeTagging == .always)
    let hinted = try #require(
      try Self.decode(#"{"value":[]}"#, types: ["f": SchemaFieldType(.timestamp, isList: true)])
    )
    #expect(hinted.value == .date(.list([])))
  }

  @Test("an empty list with neither tag nor schema type is refused")
  internal func ambiguousEmptyList() throws {
    let error = try #require(throws: DecodingError.self) {
      try Self.decode(#"{"value":[]}"#)
    }
    guard case .dataCorrupted(let context) = error else {
      Issue.record("Expected dataCorrupted, got \(error)")
      return
    }
    #expect(context.codingPath.last?.stringValue == "f")
    #expect(
      context.underlyingError as? ConversionError == .ambiguousEmptyList(fieldName: "f")
    )
  }

  @Test("a record with an untyped empty list is refused")
  internal func ambiguousEmptyListInRecord() {
    let json = #"{"recordName":"r","fields":{"tags":{"value":[]}}}"#
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(WireRecord.self, from: Data(json.utf8))
    }
  }

  @Test("a missing value is a decoding error")
  internal func missingValue() {
    #expect(throws: DecodingError.self) {
      try Self.decode(#"{"type":"STRING"}"#)
    }
  }
}

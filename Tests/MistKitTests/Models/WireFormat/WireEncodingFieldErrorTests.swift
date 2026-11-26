//
//  WireEncodingFieldErrorTests.swift
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

/// `CloudKitError(encodingError:recordNames:)` names the record and field a
/// non-finite number is in, for each shape MistKit writes.
@Suite("Wire encoding field errors")
internal struct WireEncodingFieldErrorTests {
  private static let names: [String?] = ["r0", "r1", "r2"]

  private static func record(_ name: String, _ value: FieldValue) -> RecordInfo {
    RecordInfo(
      recordName: name,
      recordType: "Note",
      fields: ["fine": .int64(.value(1)), "bad": value]
    )
  }

  private static func records(badAt index: Int, _ value: FieldValue) -> [RecordInfo] {
    (0..<3).map { position in
      record("r\(position)", position == index ? value : .double(.value(2)))
    }
  }

  /// What encoding `value` resolved to; fails the test when it encoded.
  private static func resolved(
    _ value: some Encodable,
    recordNames: [String?]
  ) -> CloudKitError? {
    do {
      _ = try JSONEncoder.cloudKitReadable.encode(value)
      Issue.record("expected encoding to fail")
      return nil
    } catch {
      return CloudKitError(encodingError: error, recordNames: recordNames)
    }
  }

  @Test(
    "a wire record array names the record and field",
    arguments: [
      FieldValue.double(.value(.nan)),
      .double(.list([1, .infinity])),
      .location(.value(Location(latitude: 0, longitude: -.infinity))),
      .location(.list([Location(latitude: 0, longitude: 0, altitude: .nan)])),
    ]
  )
  internal func wireRecords(_ value: FieldValue) {
    let records = Self.records(badAt: 1, value).map { WireRecord($0) }
    let error = Self.resolved(records, recordNames: Self.names)
    #expect(error?.recordName == "r1")
    #expect(error?.fieldName == "bad")
  }

  @Test("a modifyRecords body names the operation's record and field")
  internal func modifyBody() {
    let operations = Self.records(badAt: 2, .double(.value(.nan))).map {
      RecordOperation.create(recordType: "Note", recordName: $0.recordName, fields: $0.fields)
    }
    let error = Self.resolved(
      ModifyRecordsRequestBody(operations: operations),
      recordNames: Self.names
    )
    guard case .invalidFieldValue(let recordName, let fieldName, _) = error else {
      Issue.record("expected .invalidFieldValue, got \(String(describing: error))")
      return
    }
    #expect(recordName == "r2")
    #expect(fieldName == "bad")
  }

  @Test("a single record without an index is the only record named")
  internal func singleRecord() {
    let record = WireRecord(Self.record("solo", .double(.value(.nan))))
    let error = Self.resolved(record, recordNames: ["solo"])
    #expect(error?.recordName == "solo")
    #expect(error?.fieldName == "bad")
  }

  @Test("an error that isn't an encoding failure isn't resolved")
  internal func otherErrors() {
    #expect(CloudKitError(encodingError: CancellationError(), recordNames: ["r"]) == nil)
    let context = EncodingError.Context(codingPath: [], debugDescription: "")
    let pathless = EncodingError.invalidValue(Double.nan, context)
    #expect(CloudKitError(encodingError: pathless, recordNames: ["r"]) == nil)
  }

  @Test("a conversion error names its field and no record")
  internal func conversionError() {
    let error = CloudKitError.conversionFailed(.ambiguousEmptyList(fieldName: "tags"))
    #expect(error.fieldName == "tags")
    #expect(error.recordName == nil)
    #expect(ConversionError.recordMissingRecordName.fieldName == nil)
  }
}

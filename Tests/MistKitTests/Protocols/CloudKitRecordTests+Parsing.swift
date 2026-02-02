//
//  CloudKitRecordTests+Parsing.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

import Foundation
import Testing

@testable import MistKit

extension CloudKitRecordTests {
  @Suite("Record Parsing")
  internal struct Parsing {
    @Test("from(recordInfo:) parses valid record successfully")
    internal func fromRecordInfoSuccess() {
      let recordInfo = RecordInfo(
        recordName: "test-3",
        recordType: "TestRecord",
        fields: [
          "name": .string("Parsed Record"),
          "count": .int64(25),
          "isActive": FieldValue(booleanValue: true),
          "score": .double(75.0),
        ]
      )

      let record = TestRecord.from(recordInfo: recordInfo)

      #expect(record?.recordName == "test-3")
      #expect(record?.name == "Parsed Record")
      #expect(record?.count == 25)
      #expect(record?.isActive == true)
      #expect(record?.score == 75.0)
    }

    @Test("from(recordInfo:) handles missing optional fields")
    internal func fromRecordInfoWithMissingOptionals() {
      let recordInfo = RecordInfo(
        recordName: "test-4",
        recordType: "TestRecord",
        fields: [
          "name": .string("Minimal Record"),
          "isActive": FieldValue(booleanValue: false),
        ]
      )

      let record = TestRecord.from(recordInfo: recordInfo)

      #expect(record?.recordName == "test-4")
      #expect(record?.name == "Minimal Record")
      #expect(record?.isEmpty == true)  // Default value (count == 0)
      #expect(record?.isActive == false)
      #expect(record?.score == nil)
      #expect(record?.lastUpdated == nil)
    }

    @Test("from(recordInfo:) returns nil when required fields missing")
    internal func fromRecordInfoMissingRequiredFields() {
      let recordInfo = RecordInfo(
        recordName: "test-5",
        recordType: "TestRecord",
        fields: [
          "count": .int64(10)
          // Missing required "name" and "isActive" fields
        ]
      )

      let record = TestRecord.from(recordInfo: recordInfo)
      #expect(record == nil)
    }

    @Test("from(recordInfo:) handles legacy int64 boolean encoding")
    internal func fromRecordInfoWithLegacyBooleans() {
      let recordInfo = RecordInfo(
        recordName: "test-6",
        recordType: "TestRecord",
        fields: [
          "name": .string("Legacy Record"),
          "isActive": .int64(1),  // Legacy boolean as int64
        ]
      )

      let record = TestRecord.from(recordInfo: recordInfo)

      #expect(record?.isActive == true)
    }
  }
}

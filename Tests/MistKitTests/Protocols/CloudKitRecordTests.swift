//
//  CloudKitRecordTests.swift
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

/// Test record conforming to CloudKitRecord for testing purposes
internal struct TestRecord: CloudKitRecord {
  static var cloudKitRecordType: String { "TestRecord" }

  static func from(recordInfo: RecordInfo) -> TestRecord? {
    guard
      let name = recordInfo.fields["name"]?.stringValue,
      let isActive = recordInfo.fields["isActive"]?.boolValue
    else {
      return nil
    }

    let count = recordInfo.fields["count"]?.intValue ?? 0
    let score = recordInfo.fields["score"]?.doubleValue
    let lastUpdated = recordInfo.fields["lastUpdated"]?.dateValue

    return TestRecord(
      recordName: recordInfo.recordName,
      name: name,
      count: count,
      isActive: isActive,
      score: score,
      lastUpdated: lastUpdated
    )
  }

  static func formatForDisplay(_ recordInfo: RecordInfo) -> String {
    let name = recordInfo.fields["name"]?.stringValue ?? "Unknown"
    let count = recordInfo.fields["count"]?.intValue ?? 0
    return "  \(recordInfo.recordName): \(name) (count: \(count))"
  }

  internal var recordName: String
  internal var name: String
  internal var count: Int
  internal var isActive: Bool
  internal var score: Double?
  internal var lastUpdated: Date?

  // swiftlint:disable:next empty_count
  internal var isEmpty: Bool { count == 0 }

  internal func toCloudKitFields() -> [String: FieldValue] {
    var fields: [String: FieldValue] = [
      "name": .string(name),
      "count": .int64(count),
      "isActive": FieldValue(booleanValue: isActive),
    ]

    if let score {
      fields["score"] = .double(score)
    }

    if let lastUpdated {
      fields["lastUpdated"] = .date(lastUpdated)
    }

    return fields
  }
}

@Suite("CloudKitRecord Protocol")
internal enum CloudKitRecordTests {
  @Test("CloudKitRecord provides correct record type")
  internal static func recordTypeProperty() {
    #expect(TestRecord.cloudKitRecordType == "TestRecord")
  }
}

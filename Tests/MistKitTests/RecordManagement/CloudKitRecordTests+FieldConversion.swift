//
//  CloudKitRecordTests+FieldConversion.swift
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
  @Suite("Field Conversion")
  internal struct FieldConversion {
    @Test("toCloudKitFields converts required fields correctly")
    internal func toCloudKitFieldsBasic() {
      let record = TestRecord(
        recordName: "test-1",
        name: "Test Record",
        count: 42,
        isActive: true,
        score: nil,
        lastUpdated: nil
      )

      let fields = record.toCloudKitFields()

      #expect(fields["name"]?.stringValue == "Test Record")
      #expect(fields["count"]?.intValue == 42)
      #expect(fields["isActive"]?.boolValue == true)
      #expect(fields["score"] == nil)
      #expect(fields["lastUpdated"] == nil)
    }

    @Test("toCloudKitFields includes optional fields when present")
    internal func toCloudKitFieldsWithOptionals() {
      let date = Date()
      let record = TestRecord(
        recordName: "test-2",
        name: "Test Record",
        count: 10,
        isActive: false,
        score: 98.5,
        lastUpdated: date
      )

      let fields = record.toCloudKitFields()

      #expect(fields["name"]?.stringValue == "Test Record")
      #expect(fields["count"]?.intValue == 10)
      #expect(fields["isActive"]?.boolValue == false)
      #expect(fields["score"]?.doubleValue == 98.5)
      #expect(fields["lastUpdated"]?.dateValue == date)
    }
  }
}

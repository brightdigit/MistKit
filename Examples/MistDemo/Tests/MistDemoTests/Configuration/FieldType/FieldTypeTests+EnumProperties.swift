//
//  FieldTypeTests+EnumProperties.swift
//  MistDemo
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

import Foundation
import Testing

@testable import MistDemoKit

extension FieldTypeTests {
  @Suite("Enum Properties")
  internal struct EnumProperties {
    @Test("FieldType has all expected cases")
    internal func fieldTypeAllCases() {
      let allCases = FieldType.allCases

      #expect(allCases.contains(.string))
      #expect(allCases.contains(.int64))
      #expect(allCases.contains(.double))
      #expect(allCases.contains(.timestamp))
      #expect(allCases.contains(.asset))
      #expect(allCases.contains(.location))
      #expect(allCases.contains(.reference))
      #expect(allCases.contains(.bytes))
      #expect(allCases.count == 8)
    }

    @Test("FieldType raw values are correct")
    internal func fieldTypeRawValues() {
      #expect(FieldType.string.rawValue == "string")
      #expect(FieldType.int64.rawValue == "int64")
      #expect(FieldType.double.rawValue == "double")
      #expect(FieldType.timestamp.rawValue == "timestamp")
      #expect(FieldType.asset.rawValue == "asset")
      #expect(FieldType.location.rawValue == "location")
      #expect(FieldType.reference.rawValue == "reference")
      #expect(FieldType.bytes.rawValue == "bytes")
    }

    @Test("FieldType can be initialized from raw value")
    internal func fieldTypeInitFromRawValue() {
      #expect(FieldType(rawValue: "string") == .string)
      #expect(FieldType(rawValue: "int64") == .int64)
      #expect(FieldType(rawValue: "double") == .double)
      #expect(FieldType(rawValue: "timestamp") == .timestamp)
    }

    @Test("FieldType returns nil for invalid raw value")
    internal func fieldTypeNilForInvalidRawValue() {
      #expect(FieldType(rawValue: "invalid") == nil)
      #expect(FieldType(rawValue: "STRING") == nil)  // case-sensitive
      #expect(FieldType(rawValue: "") == nil)
    }
  }
}

//
//  CloudKitServiceQueryTests+FilterConversion.swift
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

extension CloudKitServiceQueryTests {
  @Suite("Filter Conversion")
  internal struct FilterConversion {
    @Test("QueryFilter converts to Components.Schemas format correctly")
    internal func queryFilterConvertsToComponentsFormat() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      // Test equality filter
      let equalFilter = QueryFilter.equals("title", .string("Test"))
      let componentsFilter = Components.Schemas.Filter(from: equalFilter)

      #expect(componentsFilter.fieldName == "title")
      #expect(componentsFilter.comparator == .EQUALS)

      // Test comparison filter
      let greaterThanFilter = QueryFilter.greaterThan("count", .int64(10))
      let componentsGT = Components.Schemas.Filter(from: greaterThanFilter)

      #expect(componentsGT.fieldName == "count")
      #expect(componentsGT.comparator == .GREATER_THAN)
    }

    @Test("QueryFilter handles all field value types")
    internal func queryFilterHandlesAllFieldValueTypes() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let testCases: [(FieldValue, String)] = [
        (.string("test"), "string"),
        (.int64(42), "int64"),
        (.double(3.14), "double"),
        (FieldValue(booleanValue: true), "boolean"),
        (.date(Date()), "date"),
      ]

      for (fieldValue, typeName) in testCases {
        let filter = QueryFilter.equals("field", fieldValue)
        let components = Components.Schemas.Filter(from: filter)

        #expect(components.fieldName == "field")
        #expect(components.comparator == .EQUALS, "Failed for \(typeName)")
      }
    }
  }
}

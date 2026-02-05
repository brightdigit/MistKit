//
//  CloudKitServiceQueryTests+SortConversion.swift
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
  @Suite("Sort Conversion")
  internal struct SortConversion {
    @Test("QuerySort converts to Components.Schemas format correctly")
    internal func querySortConvertsToComponentsFormat() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      // Test ascending sort
      let ascendingSort = QuerySort.ascending("createdAt")
      let componentsAsc = Components.Schemas.Sort(from: ascendingSort)

      #expect(componentsAsc.fieldName == "createdAt")
      #expect(componentsAsc.ascending == true)

      // Test descending sort
      let descendingSort = QuerySort.descending("modifiedAt")
      let componentsDesc = Components.Schemas.Sort(from: descendingSort)

      #expect(componentsDesc.fieldName == "modifiedAt")
      #expect(componentsDesc.ascending == false)
    }

    @Test("QuerySort handles various field name formats")
    internal func querySortHandlesVariousFieldNameFormats() {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let fieldNames = [
        "simpleField",
        "camelCaseField",
        "snake_case_field",
        "field123",
        "field_with_multiple_underscores",
      ]

      for fieldName in fieldNames {
        let sort = QuerySort.ascending(fieldName)
        let components = Components.Schemas.Sort(from: sort)

        #expect(components.fieldName == fieldName, "Failed for field name: \(fieldName)")
      }
    }
  }
}

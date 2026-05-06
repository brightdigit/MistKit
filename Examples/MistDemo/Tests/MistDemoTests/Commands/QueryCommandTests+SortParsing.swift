//
//  QueryCommandTests+SortParsing.swift
//  MistDemoTests
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

extension QueryCommandTests {
  @Suite("Sort Parsing")
  internal struct SortParsing {
    @Test("Parse ascending sort")
    internal func parseAscendingSort() {
      let sort = "createdAt:asc"
      let parts = sort.split(separator: ":").map(String.init)

      #expect(parts.count == 2)
      #expect(parts[0] == "createdAt")
      #expect(parts[1] == "asc")
      #expect(SortOrder(rawValue: parts[1]) == .ascending)
    }

    @Test("Parse descending sort")
    internal func parseDescendingSort() {
      let sort = "modifiedAt:desc"
      let parts = sort.split(separator: ":").map(String.init)

      #expect(parts.count == 2)
      #expect(parts[0] == "modifiedAt")
      #expect(parts[1] == "desc")
      #expect(SortOrder(rawValue: parts[1]) == .descending)
    }

    @Test("SortOrder enum values")
    internal func sortOrderEnumValues() {
      #expect(SortOrder.ascending.rawValue == "asc")
      #expect(SortOrder.descending.rawValue == "desc")
      #expect(SortOrder.allCases.count == 2)
    }
  }
}

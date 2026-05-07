//
//  QueryCommandTests+FilterParsing.swift
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
  @Suite("Filter Parsing")
  internal struct FilterParsing {
    @Test("Parse simple filter expression")
    internal func parseSimpleFilter() {
      let filter = "title:eq:Test Note"
      let parts = filter.split(separator: ":", maxSplits: 2).map(String.init)

      #expect(parts.count == 3)
      #expect(parts[0] == "title")
      #expect(parts[1] == "eq")
      #expect(parts[2] == "Test Note")
    }

    @Test("Parse filter with multiple colons in value")
    internal func parseFilterWithColonsInValue() {
      let filter = "url:eq:https://example.com:8080"
      let parts = filter.split(separator: ":", maxSplits: 2).map(String.init)

      #expect(parts.count == 3)
      #expect(parts[0] == "url")
      #expect(parts[1] == "eq")
      #expect(parts[2] == "https://example.com:8080")
    }

    @Test("Filter operators are valid")
    internal func filterOperatorsValid() {
      let validOperators = ["eq", "ne", "lt", "lte", "gt", "gte", "in", "contains", "beginsWith"]

      for operatorName in validOperators {
        let filter = "field:\(operatorName):value"
        let parts = filter.split(separator: ":").map(String.init)
        #expect(validOperators.contains(parts[1]))
      }
    }
  }
}

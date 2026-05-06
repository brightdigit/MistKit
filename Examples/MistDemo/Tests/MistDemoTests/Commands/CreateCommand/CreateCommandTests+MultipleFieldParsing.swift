//
//  CreateCommandTests+MultipleFieldParsing.swift
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

extension CreateCommandTests {
  @Suite("Multiple Field Parsing")
  internal struct MultipleFieldParsing {
    @Test("Parse multiple fields from comma-separated string")
    internal func parseMultipleFieldsFromString() async throws {
      let fieldsString = "title:string:Test Note, priority:int64:5, progress:double:0.5"
      let fields = try fieldsString.split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .map { try Field(parsing: String($0)) }

      #expect(fields.count == 3)
      #expect(fields[0].name == "title")
      #expect(fields[1].name == "priority")
      #expect(fields[2].name == "progress")
    }
  }
}

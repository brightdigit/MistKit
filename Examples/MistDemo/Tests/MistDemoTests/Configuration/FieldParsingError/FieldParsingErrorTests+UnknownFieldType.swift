//
//  FieldParsingErrorTests+UnknownFieldType.swift
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

extension FieldParsingErrorTests {
  @Suite("unknownFieldType Error")
  internal struct UnknownFieldType {
    @Test("unknownFieldType error has correct description")
    func unknownFieldTypeErrorDescription() {
      let error = FieldParsingError.unknownFieldType("invalid", available: ["string", "int64"])
      let description = error.errorDescription

      #expect(description != nil)
      #expect(description?.contains("Unknown field type") == true)
      #expect(description?.contains("invalid") == true)
      #expect(description?.contains("string") == true)
      #expect(description?.contains("int64") == true)
    }

    @Test("unknownFieldType error is thrown for invalid type")
    func unknownFieldTypeErrorThrown() {
      do {
        _ = try Field(parsing: "name:invalid:value")
        Issue.record("Expected unknownFieldType error to be thrown")
      } catch let error as FieldParsingError {
        if case .unknownFieldType = error {
          // Success
        } else {
          Issue.record("Expected unknownFieldType error, got \(error)")
        }
      } catch {
        Issue.record("Expected FieldParsingError, got \(error)")
      }
    }
  }
}

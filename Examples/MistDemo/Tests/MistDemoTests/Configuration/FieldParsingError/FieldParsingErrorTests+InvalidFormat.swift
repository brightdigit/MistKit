//
//  FieldParsingErrorTests+InvalidFormat.swift
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
  @Suite("invalidFormat Error")
  internal struct InvalidFormat {
    @Test("invalidFormat error has correct description")
    func invalidFormatErrorDescription() {
      let error = FieldParsingError.invalidFormat("title:string", expected: "name:type:value")
      let description = error.errorDescription

      #expect(description != nil)
      #expect(description?.contains("Invalid field format") == true)
      #expect(description?.contains("title:string") == true)
      #expect(description?.contains("name:type:value") == true)
    }

    @Test("invalidFormat error is thrown for missing parts")
    func invalidFormatErrorThrown() {
      do {
        _ = try Field(parsing: "incomplete")
        Issue.record("Expected invalidFormat error to be thrown")
      } catch let error as FieldParsingError {
        if case .invalidFormat = error {
          // Success
        } else {
          Issue.record("Expected invalidFormat error, got \(error)")
        }
      } catch {
        Issue.record("Expected FieldParsingError, got \(error)")
      }
    }
  }
}

//
//  FieldParsingErrorTests+InvalidValueForType.swift
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
  @Suite("invalidValueForType Error")
  internal struct InvalidValueForType {
    @Test("invalidValueForType error has correct description for int64")
    internal func invalidValueForTypeInt64ErrorDescription() {
      let error = FieldParsingError.invalidValueForType("not-a-number", type: .int64)
      let description = error.errorDescription

      #expect(description != nil)
      #expect(description?.contains("Invalid value") == true)
      #expect(description?.contains("not-a-number") == true)
      #expect(description?.contains("int64") == true)
    }

    @Test("invalidValueForType error has correct description for double")
    internal func invalidValueForTypeDoubleErrorDescription() {
      let error = FieldParsingError.invalidValueForType("not-a-number", type: .double)
      let description = error.errorDescription

      #expect(description != nil)
      #expect(description?.contains("Invalid value") == true)
      #expect(description?.contains("not-a-number") == true)
      #expect(description?.contains("double") == true)
    }

    @Test("invalidValueForType error is thrown for invalid int64")
    internal func invalidValueForTypeInt64ErrorThrown() {
      do {
        _ = try FieldType.int64.convertValue("not-a-number")
        Issue.record("Expected invalidValueForType error to be thrown")
      } catch let error as FieldParsingError {
        if case .invalidValueForType = error {
          // Success
        } else {
          Issue.record("Expected invalidValueForType error, got \(error)")
        }
      } catch {
        Issue.record("Expected FieldParsingError, got \(error)")
      }
    }

    @Test("invalidValueForType error is thrown for invalid double")
    internal func invalidValueForTypeDoubleErrorThrown() {
      do {
        _ = try FieldType.double.convertValue("not-a-number")
        Issue.record("Expected invalidValueForType error to be thrown")
      } catch let error as FieldParsingError {
        if case .invalidValueForType = error {
          // Success
        } else {
          Issue.record("Expected invalidValueForType error, got \(error)")
        }
      } catch {
        Issue.record("Expected FieldParsingError, got \(error)")
      }
    }
  }
}

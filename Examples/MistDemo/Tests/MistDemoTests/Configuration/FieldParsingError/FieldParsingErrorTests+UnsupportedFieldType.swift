//
//  FieldParsingErrorTests+UnsupportedFieldType.swift
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

internal import Foundation
internal import Testing

@testable import MistDemoKit

extension FieldParsingErrorTests {
  @Suite("unsupportedFieldType Error")
  internal struct UnsupportedFieldType {
    @Test("unsupportedFieldType error has correct description for asset")
    internal func unsupportedFieldTypeAssetErrorDescription() {
      let error = FieldParsingError.unsupportedFieldType(.asset)
      let description = error.errorDescription

      #expect(description != nil)
      #expect(description?.contains("not yet supported") == true)
      #expect(description?.contains("asset") == true)
    }

    @Test("unsupportedFieldType error has correct description for location")
    internal func unsupportedFieldTypeLocationErrorDescription() {
      let error = FieldParsingError.unsupportedFieldType(.location)
      let description = error.errorDescription

      #expect(description != nil)
      #expect(description?.contains("not yet supported") == true)
      #expect(description?.contains("location") == true)
    }

    @Test("unsupportedFieldType error is thrown for location type")
    internal func unsupportedFieldTypeAssetErrorThrown() {
      do {
        _ = try FieldType.location.convertValue("anything")
        Issue.record("Expected unsupportedFieldType error to be thrown")
      } catch let error as FieldParsingError {
        if case .unsupportedFieldType = error {
          // Success
        } else {
          Issue.record("Expected unsupportedFieldType error, got \(error)")
        }
      } catch {
        Issue.record("Expected FieldParsingError, got \(error)")
      }
    }

    @Test("unsupportedFieldType error is thrown for bytes type")
    internal func unsupportedFieldTypeBytesErrorThrown() {
      do {
        _ = try FieldType.bytes.convertValue("anything")
        Issue.record("Expected unsupportedFieldType error to be thrown")
      } catch let error as FieldParsingError {
        if case .unsupportedFieldType = error {
          // Success
        } else {
          Issue.record("Expected unsupportedFieldType error, got \(error)")
        }
      } catch {
        Issue.record("Expected FieldParsingError, got \(error)")
      }
    }
  }
}

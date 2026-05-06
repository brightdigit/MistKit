//
//  CreateErrorTests+ErrorDescription.swift
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

extension CreateErrorTests {
  @Suite("Error Description")
  internal struct ErrorDescription {
    @Test("noFieldsProvided error description")
    internal func noFieldsProvidedDescription() {
      let error = CreateError.noFieldsProvided
      let description = error.errorDescription

      #expect(description != nil)
      #expect(description == MistDemoConstants.Messages.noFieldsProvided)
    }

    @Test("invalidJSONFormat error description")
    internal func invalidJSONFormatDescription() {
      let error = CreateError.invalidJSONFormat("unexpected token")
      let description = error.errorDescription

      #expect(description != nil)
      #expect(description?.contains("Invalid JSON format") == true)
      #expect(description?.contains("unexpected token") == true)
    }

    @Test("jsonFileError error description")
    internal func jsonFileErrorDescription() {
      let error = CreateError.jsonFileError("test.json", "file not found")
      let description = error.errorDescription

      #expect(description != nil)
      #expect(description?.contains("Error reading JSON file") == true)
      #expect(description?.contains("test.json") == true)
      #expect(description?.contains("file not found") == true)
    }

    @Test("emptyStdin error description")
    internal func emptyStdinDescription() {
      let error = CreateError.emptyStdin
      let description = error.errorDescription

      #expect(description != nil)
      #expect(description?.contains("Empty stdin") == true)
      #expect(description?.contains("JSON object") == true)
    }

    @Test("stdinError error description")
    internal func stdinErrorDescription() {
      let error = CreateError.stdinError("read failed")
      let description = error.errorDescription

      #expect(description != nil)
      #expect(description?.contains("Error reading from stdin") == true)
      #expect(description?.contains("read failed") == true)
    }

    @Test("fieldConversionError error description")
    internal func fieldConversionErrorDescription() {
      let error = CreateError.fieldConversionError("age", .int64, "invalid", "not a number")
      let description = error.errorDescription

      #expect(description != nil)
      #expect(description?.contains("Failed to convert field") == true)
      #expect(description?.contains("age") == true)
      #expect(description?.contains("int64") == true)
      #expect(description?.contains("invalid") == true)
      #expect(description?.contains("not a number") == true)
    }

    @Test("operationFailed error description")
    internal func operationFailedDescription() {
      let error = CreateError.operationFailed("network timeout")
      let description = error.errorDescription

      #expect(description != nil)
      #expect(description?.contains("Create operation failed") == true)
      #expect(description?.contains("network timeout") == true)
    }
  }
}

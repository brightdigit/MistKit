//
//  MistDemoErrorTests+ErrorOutputConversion.swift
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

internal import Foundation
internal import Testing

@testable import MistDemoKit

extension MistDemoErrorTests {
  @Suite("Error Output Conversion")
  internal struct ErrorOutputConversion {
    @Test("Convert error to ErrorOutput")
    internal func convertToErrorOutput() {
      let error = MistDemoError.fileNotFound("/path/to/file")
      let output = error.errorOutput

      #expect(output.error.code == "FILE_NOT_FOUND")
      #expect(output.error.message.contains("not found") == true)
      #expect(output.error.details?["path"] == "/path/to/file")
    }

    @Test("ErrorOutput includes suggestion when available")
    internal func errorOutputIncludesSuggestion() {
      let error = MistDemoError.configurationError(
        "Missing token",
        suggestion: "Use --api-token flag"
      )
      let output = error.errorOutput

      #expect(output.error.suggestion == "Use --api-token flag")
    }

    @Test("ErrorOutput omits empty details")
    internal func errorOutputOmitsEmptyDetails() {
      let error = MistDemoError.outputFormattingFailed(
        description: "Encoding failed"
      )
      let output = error.errorOutput

      #expect(output.error.details == nil || output.error.details?.isEmpty == true)
    }
  }
}

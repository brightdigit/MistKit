//
//  YAMLFormatterTests+MultilineString.swift
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
internal import MistKit
internal import Testing

@testable import MistDemoKit

extension YAMLFormatterTests {
  @Suite("Multiline String")
  internal struct MultilineString {
    @Test("Format RecordInfo with multiline block scalar")
    internal func formatRecordWithMultilineBlockScalar() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Multiline",
        fields: [
          "description": .string("First line\nSecond line\nThird line")
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      // Should use literal block scalar
      #expect(output.contains("  description: |"))
      #expect(output.contains("    First line"))
      #expect(output.contains("    Second line"))
      #expect(output.contains("    Third line"))
    }

    @Test("Format RecordInfo with multiline and empty lines")
    internal func formatRecordWithMultilineAndEmptyLines() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Multiline",
        fields: [
          "text": .string("Line 1\n\nLine 3")
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      // Should preserve empty lines in block scalar
      #expect(output.contains("  text: |"))
    }
  }
}

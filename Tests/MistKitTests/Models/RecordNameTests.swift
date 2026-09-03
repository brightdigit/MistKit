//
//  RecordNameTests.swift
//  MistKit
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
internal import MistKitOpenAPI
internal import Testing

@testable import MistKit

@Suite("RecordName")
internal struct RecordNameTests {
  @Test("encodes and decodes as a single JSON string")
  internal func codableRoundTripIsASingleJSONString() throws {
    let name: RecordName = "custom-note-1"
    let encoded = try JSONEncoder().encode(name)
    #expect(String(data: encoded, encoding: .utf8) == "\"custom-note-1\"")

    let decoded = try JSONDecoder().decode(RecordName.self, from: encoded)
    #expect(decoded == name)
    #expect(decoded.rawValue == "custom-note-1")
  }

  @Test("accepts a string literal at the call site")
  internal func stringLiteralInitializesRecordName() {
    let name: RecordName = "550e8400-e29b-41d4-a716-446655440000"
    #expect(name == RecordName(rawValue: "550e8400-e29b-41d4-a716-446655440000"))
    #expect(name.description == "550e8400-e29b-41d4-a716-446655440000")
  }

  @Test("Reference conversion still maps the record name to the OpenAPI string")
  internal func referenceConversionUsesTheWireString() {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("FieldValue is not available on this operating system.")
      return
    }
    let reference = Reference(recordName: "parent-record-123", action: .deleteSelf)
    let request = Components.Schemas.FieldValueRequest(from: .reference(reference))

    guard case .ReferenceValue(let value) = request.value else {
      Issue.record("Expected ReferenceValue")
      return
    }
    #expect(value.recordName == "parent-record-123")
    #expect(value.action == .DELETE_SELF)

    let fieldValue = FieldValue(referenceValue: value)
    #expect(fieldValue == .reference(reference))
  }
}

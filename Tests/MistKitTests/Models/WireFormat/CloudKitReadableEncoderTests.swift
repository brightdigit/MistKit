//
//  CloudKitReadableEncoderTests.swift
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
internal import Testing

@testable import MistKit

/// `JSONEncoder.cloudKitReadable` (MistKit #503).
@Suite("CloudKit readable encoder")
internal struct CloudKitReadableEncoderTests {
  @Test("pretty prints, sorts keys and leaves slashes alone")
  internal func options() throws {
    let encoder = JSONEncoder.cloudKitReadable
    #expect(encoder.outputFormatting.contains(.prettyPrinted))
    #expect(encoder.outputFormatting.contains(.sortedKeys))
    #expect(encoder.outputFormatting.contains(.withoutEscapingSlashes))
    let json = String(decoding: try encoder.encode(["url": "https://a/b"]), as: UTF8.self)
    #expect(json == "{\n  \"url\" : \"https://a/b\"\n}")
  }

  @Test("each call returns a fresh encoder")
  internal func fresh() {
    let first = JSONEncoder.cloudKitReadable
    first.outputFormatting = []
    #expect(JSONEncoder.cloudKitReadable.outputFormatting.contains(.sortedKeys))
  }

  @Test("output doesn't depend on dictionary insertion order")
  internal func insertionOrder() throws {
    var forward: [String: FieldValue] = [:]
    var backward: [String: FieldValue] = [:]
    let names = (0..<32).map { "field\($0)" }
    for name in names {
      forward[name] = .string(.value(name))
    }
    for name in names.reversed() {
      backward[name] = .string(.value(name))
    }
    let lhs = WireRecord(recordName: "r", recordType: "T", fields: forward)
    let rhs = WireRecord(recordName: "r", recordType: "T", fields: backward)
    #expect(
      try JSONEncoder.cloudKitReadable.encode(lhs) == JSONEncoder.cloudKitReadable.encode(rhs)
    )
  }
}

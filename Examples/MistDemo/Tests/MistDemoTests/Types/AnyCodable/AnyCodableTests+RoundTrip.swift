//
//  AnyCodableTests+RoundTrip.swift
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

extension AnyCodableTests {
  @Suite("Round-trip")
  internal struct RoundTrip {
    @Test("Round-trip string value")
    internal func roundTripString() throws {
      let original = "hello"
      let anyCodable = try AnyCodable(value: original)
      let data = try JSONEncoder().encode(anyCodable)
      let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
      #expect(decoded.value as? String == original)
    }

    @Test("Round-trip integer value")
    internal func roundTripInteger() throws {
      let original = 42
      let anyCodable = try AnyCodable(value: original)
      let data = try JSONEncoder().encode(anyCodable)
      let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
      #expect(decoded.value as? Int == original)
    }

    @Test("Round-trip double value")
    internal func roundTripDouble() throws {
      let original = 3.14159
      let anyCodable = try AnyCodable(value: original)
      let data = try JSONEncoder().encode(anyCodable)
      let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
      #expect(decoded.value as? Double == original)
    }

    @Test("Round-trip boolean value")
    internal func roundTripBoolean() throws {
      let original = true
      let anyCodable = try AnyCodable(value: original)
      let data = try JSONEncoder().encode(anyCodable)
      let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
      #expect(decoded.value as? Bool == original)
    }
  }
}

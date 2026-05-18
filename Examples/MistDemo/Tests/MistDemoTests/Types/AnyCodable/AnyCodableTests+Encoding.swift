//
//  AnyCodableTests+Encoding.swift
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
  @Suite("Encoding")
  internal struct Encoding {
    @Test("Encode string value")
    internal func encodeString() throws {
      let anyCodable = try AnyCodable(value: "test")
      let data = try JSONEncoder().encode(anyCodable)
      let json = try #require(String(data: data, encoding: .utf8))
      #expect(json == "\"test\"")
    }

    @Test("Encode integer value")
    internal func encodeInteger() throws {
      let anyCodable = try AnyCodable(value: 123)
      let data = try JSONEncoder().encode(anyCodable)
      let json = try #require(String(data: data, encoding: .utf8))
      #expect(json == "123")
    }

    @Test("Encode double value")
    internal func encodeDouble() throws {
      let anyCodable = try AnyCodable(value: 3.14)
      let data = try JSONEncoder().encode(anyCodable)
      let json = try #require(String(data: data, encoding: .utf8))
      #expect(json.contains("3.14"))
    }

    @Test("Encode boolean value")
    internal func encodeBoolean() throws {
      let anyCodable = try AnyCodable(value: true)
      let data = try JSONEncoder().encode(anyCodable)
      let json = try #require(String(data: data, encoding: .utf8))
      #expect(json == "true")
    }

    @Test("Encode null value")
    internal func encodeNull() throws {
      let anyCodable = try AnyCodable(value: NSNull())
      let data = try JSONEncoder().encode(anyCodable)
      let json = try #require(String(data: data, encoding: .utf8))
      #expect(json == "null")
    }
  }
}

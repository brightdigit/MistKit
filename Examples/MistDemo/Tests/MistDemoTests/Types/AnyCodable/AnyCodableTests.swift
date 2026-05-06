//
//  AnyCodableTests.swift
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

@Suite("AnyCodable")
internal enum AnyCodableTests {}

// MARK: - AnyCodable Test Helper

extension AnyCodable {
  /// Test helper that creates AnyCodable by encoding and decoding a value
  internal init(value: Any) throws {
    // For simple Codable types, encode to JSON and decode as AnyCodable
    struct Wrapper: Codable {
      let value: AnyCodable
    }

    // Encode the value to JSON data
    let jsonData: Data
    if let stringValue = value as? String {
      jsonData = try JSONEncoder().encode(stringValue)
    } else if let intValue = value as? Int {
      jsonData = try JSONEncoder().encode(intValue)
    } else if let doubleValue = value as? Double {
      jsonData = try JSONEncoder().encode(doubleValue)
    } else if let boolValue = value as? Bool {
      jsonData = try JSONEncoder().encode(boolValue)
    } else if value is NSNull {
      jsonData = Data("null".utf8)
    } else {
      // For other types, fail gracefully
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: [],
          debugDescription: "Unsupported type for test helper: \(type(of: value))"
        )
      )
    }

    // Decode as AnyCodable
    self = try JSONDecoder().decode(AnyCodable.self, from: jsonData)
  }
}

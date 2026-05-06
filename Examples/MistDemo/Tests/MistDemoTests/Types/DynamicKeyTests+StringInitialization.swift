//
//  DynamicKeyTests+StringInitialization.swift
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

extension DynamicKeyTests {
  @Suite("String Initialization")
  internal struct StringInitialization {
    @Test("Initialize with string value")
    internal func initWithStringValue() {
      let key = DynamicKey(stringValue: "testKey")
      #expect(key != nil)
      #expect(key?.stringValue == "testKey")
      #expect(key?.intValue == nil)
    }

    @Test("Initialize with empty string")
    internal func initWithEmptyString() {
      let key = DynamicKey(stringValue: "")
      #expect(key != nil)
      #expect(key?.stringValue == "")
      #expect(key?.intValue == nil)
    }

    @Test("Initialize with string containing numbers")
    internal func initWithNumericString() {
      let key = DynamicKey(stringValue: "123")
      #expect(key != nil)
      #expect(key?.stringValue == "123")
      #expect(key?.intValue == nil)
    }

    @Test("Initialize with string containing special characters")
    internal func initWithSpecialCharacters() {
      let key = DynamicKey(stringValue: "field_name-123")
      #expect(key != nil)
      #expect(key?.stringValue == "field_name-123")
    }
  }
}

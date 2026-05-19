//
//  DynamicKeyTests+IntegerInitialization.swift
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

extension DynamicKeyTests {
  @Suite("Integer Initialization")
  internal struct IntegerInitialization {
    @Test("Initialize with integer value")
    internal func initWithIntValue() {
      let key = DynamicKey(intValue: 42)
      #expect(key != nil)
      #expect(key?.stringValue == "42")
      #expect(key?.intValue == 42)
    }

    @Test("Initialize with zero")
    internal func initWithZero() {
      let key = DynamicKey(intValue: 0)
      #expect(key != nil)
      #expect(key?.stringValue == "0")
      #expect(key?.intValue == 0)
    }

    @Test("Initialize with negative integer")
    internal func initWithNegativeInt() {
      let key = DynamicKey(intValue: -5)
      #expect(key != nil)
      #expect(key?.stringValue == "-5")
      #expect(key?.intValue == -5)
    }
  }
}

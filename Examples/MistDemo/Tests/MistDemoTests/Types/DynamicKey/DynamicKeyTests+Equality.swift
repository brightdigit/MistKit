//
//  DynamicKeyTests+Equality.swift
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

internal import Testing

@testable import MistDemoKit

extension DynamicKeyTests {
  @Suite("Equality")
  internal struct Equality {
    @Test("Keys with same string value are equal")
    internal func keysWithSameStringEqual() {
      let key1 = DynamicKey(stringValue: "test")
      let key2 = DynamicKey(stringValue: "test")
      #expect(key1?.stringValue == key2?.stringValue)
    }

    @Test("Keys with different string values are not equal")
    internal func keysWithDifferentStringNotEqual() {
      let key1 = DynamicKey(stringValue: "test1")
      let key2 = DynamicKey(stringValue: "test2")
      #expect(key1?.stringValue != key2?.stringValue)
    }
  }
}

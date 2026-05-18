//
//  ConfigKey+MistDemoTests+ConfigKeyWithPrefix.swift
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

internal import ConfigKeyKit
internal import Foundation
internal import Testing

@testable import MistDemoKit

extension ConfigKeyMistDemoTests {
  @Suite("ConfigKey with MISTDEMO Prefix")
  internal struct ConfigKeyWithPrefix {
    @Test("ConfigKey with mistDemoPrefixed initializer")
    internal func configKeyWithMistDemoPrefix() {
      let key = ConfigKey(mistDemoPrefixed: "test.key", default: "default-value")

      #expect(key.base == "test.key")
      #expect(key.defaultValue == "default-value")
    }

    @Test("ConfigKey mistDemoPrefixed with string default")
    internal func mistDemoPrefixedStringDefault() {
      let key = ConfigKey(mistDemoPrefixed: "api.token", default: "default-token")

      #expect(key.base == "api.token")
      #expect(key.defaultValue == "default-token")
    }

    @Test("ConfigKey mistDemoPrefixed with different base keys")
    internal func mistDemoPrefixedDifferentKeys() {
      let key1 = ConfigKey(mistDemoPrefixed: "key.one", default: "value1")
      let key2 = ConfigKey(mistDemoPrefixed: "key.two", default: "value2")

      #expect(key1.base != key2.base)
      #expect(key1.defaultValue != key2.defaultValue)
    }
  }
}

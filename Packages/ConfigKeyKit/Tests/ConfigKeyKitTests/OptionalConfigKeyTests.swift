//
//  OptionalConfigKeyTests.swift
//  ConfigKeyKit
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

import Testing

@testable import ConfigKeyKit

@Suite("OptionalConfigKey Tests")
internal struct OptionalConfigKeyTests {
  @Test("OptionalConfigKey with explicit keys")
  internal func explicitKeys() {
    let key = OptionalConfigKey<String>(cli: "test.key", env: "TEST_KEY")

    #expect(key.key(for: .commandLine) == "test.key")
    #expect(key.key(for: .environment) == "TEST_KEY")
  }

  @Test("OptionalConfigKey with base string and custom env prefix")
  internal func baseStringWithCustomPrefix() {
    let key = OptionalConfigKey<String>("cloudkit.key_id", envPrefix: "MYAPP")

    #expect(key.key(for: .commandLine) == "cloudkit.key_id")
    #expect(key.key(for: .environment) == "MYAPP_CLOUDKIT_KEY_ID")
  }

  @Test("OptionalConfigKey with base string and no prefix")
  internal func baseStringNoPrefix() {
    let key = OptionalConfigKey<String>("cloudkit.key_id", envPrefix: nil)

    #expect(key.key(for: .commandLine) == "cloudkit.key_id")
    #expect(key.key(for: .environment) == "CLOUDKIT_KEY_ID")
  }

  @Test("OptionalConfigKey and ConfigKey generate identical keys")
  internal func keyGenerationParity() {
    let optional = OptionalConfigKey<String>("test.key", envPrefix: "MYAPP")
    let withDefault = ConfigKey<String>("test.key", envPrefix: "MYAPP", default: "default")

    #expect(optional.key(for: .commandLine) == withDefault.key(for: .commandLine))
    #expect(optional.key(for: .environment) == withDefault.key(for: .environment))
  }

  @Test("OptionalConfigKey for Int type")
  internal func intOptionalKey() {
    let key = OptionalConfigKey<Int>("sync.min_interval", envPrefix: "MYAPP")

    #expect(key.key(for: .commandLine) == "sync.min_interval")
    #expect(key.key(for: .environment) == "MYAPP_SYNC_MIN_INTERVAL")
  }

  @Test("OptionalConfigKey for Double type")
  internal func doubleOptionalKey() {
    let key = OptionalConfigKey<Double>("fetch.interval_global", envPrefix: "MYAPP")

    #expect(key.key(for: .commandLine) == "fetch.interval_global")
    #expect(key.key(for: .environment) == "MYAPP_FETCH_INTERVAL_GLOBAL")
  }
}

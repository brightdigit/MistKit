//
//  ConfigKeyTests.swift
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

@Suite("ConfigKey Tests")
internal struct ConfigKeyTests {
  @Test("ConfigKey with explicit keys and default")
  internal func explicitKeys() {
    let key = ConfigKey<String>(cli: "test.key", env: "TEST_KEY", default: "default-value")

    #expect(key.key(for: .commandLine) == "test.key")
    #expect(key.key(for: .environment) == "TEST_KEY")
    #expect(key.defaultValue == "default-value")
  }

  @Test("ConfigKey with base string and custom env prefix")
  internal func baseStringWithCustomPrefix() {
    let key = ConfigKey<String>(
      "cloudkit.container_id", envPrefix: "MYAPP", default: "iCloud.com.example.App"
    )

    #expect(key.key(for: .commandLine) == "cloudkit.container_id")
    #expect(key.key(for: .environment) == "MYAPP_CLOUDKIT_CONTAINER_ID")
    #expect(key.defaultValue == "iCloud.com.example.App")
  }

  @Test("ConfigKey with base string and no prefix")
  internal func baseStringNoPrefix() {
    let key = ConfigKey<String>(
      "cloudkit.container_id", envPrefix: nil, default: "iCloud.com.example.App"
    )

    #expect(key.key(for: .commandLine) == "cloudkit.container_id")
    #expect(key.key(for: .environment) == "CLOUDKIT_CONTAINER_ID")
    #expect(key.defaultValue == "iCloud.com.example.App")
  }

  @Test("ConfigKey exposes its base string")
  internal func baseAccessor() {
    let withBase = ConfigKey<String>("cloudkit.container_id", default: "default")
    let withoutBase = ConfigKey<String>(cli: "x", env: "X", default: "default")

    #expect(withBase.base == "cloudkit.container_id")
    #expect(withoutBase.base == nil)
  }

  @Test("Boolean ConfigKey with default")
  internal func booleanDefaultValue() {
    let key = ConfigKey<Bool>("sync.verbose", envPrefix: "MYAPP", default: false)

    #expect(key.defaultValue == false)
    #expect(key.key(for: .environment) == "MYAPP_SYNC_VERBOSE")
  }
}

//
//  ConfigKey+MistDemoTests.swift
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
@testable import MistDemo
import ConfigKeyKit

@Suite("ConfigKey+MistDemo Tests")
struct ConfigKeyMistDemoTests {

    // MARK: - ConfigKey with MISTDEMO Prefix Tests

    @Test("ConfigKey with mistDemoPrefixed initializer")
    func configKeyWithMistDemoPrefix() {
        let key = ConfigKey(mistDemoPrefixed: "test.key", default: "default-value")

        #expect(key.base == "test.key")
        #expect(key.defaultValue == "default-value")
    }

    @Test("ConfigKey mistDemoPrefixed with string default")
    func mistDemoPrefixedStringDefault() {
        let key = ConfigKey(mistDemoPrefixed: "api.token", default: "default-token")

        #expect(key.base == "api.token")
        #expect(key.defaultValue == "default-token")
    }

    @Test("ConfigKey mistDemoPrefixed with different base keys")
    func mistDemoPrefixedDifferentKeys() {
        let key1 = ConfigKey(mistDemoPrefixed: "key.one", default: "value1")
        let key2 = ConfigKey(mistDemoPrefixed: "key.two", default: "value2")

        #expect(key1.base != key2.base)
        #expect(key1.defaultValue != key2.defaultValue)
    }

    // MARK: - OptionalConfigKey with MISTDEMO Prefix Tests

    @Test("OptionalConfigKey with mistDemoPrefixed initializer")
    func optionalConfigKeyWithMistDemoPrefix() {
        let key = OptionalConfigKey<String>(mistDemoPrefixed: "optional.key")

        #expect(key.base == "optional.key")
    }

    @Test("OptionalConfigKey mistDemoPrefixed for different types")
    func optionalConfigKeyDifferentTypes() {
        let stringKey = OptionalConfigKey<String>(mistDemoPrefixed: "string.key")
        let intKey = OptionalConfigKey<Int>(mistDemoPrefixed: "int.key")

        #expect(stringKey.base == "string.key")
        #expect(intKey.base == "int.key")
    }

    // MARK: - Boolean ConfigKey with MISTDEMO Prefix Tests

    @Test("Boolean ConfigKey with mistDemoPrefixed and default true")
    func booleanConfigKeyDefaultTrue() {
        let key = ConfigKey<Bool>(mistDemoPrefixed: "debug.enabled", default: true)

        #expect(key.base == "debug.enabled")
        #expect(key.defaultValue == true)
    }

    @Test("Boolean ConfigKey with mistDemoPrefixed and default false")
    func booleanConfigKeyDefaultFalse() {
        let key = ConfigKey<Bool>(mistDemoPrefixed: "feature.flag", default: false)

        #expect(key.base == "feature.flag")
        #expect(key.defaultValue == false)
    }

    @Test("Boolean ConfigKey with implicit default false")
    func booleanConfigKeyImplicitDefault() {
        let key = ConfigKey<Bool>(mistDemoPrefixed: "test.flag")

        #expect(key.base == "test.flag")
        #expect(key.defaultValue == false)
    }

    // MARK: - Real-world Usage Tests

    @Test("Create config key for container identifier")
    func containerIdentifierKey() {
        let key = ConfigKey(
            mistDemoPrefixed: "container.identifier",
            default: "iCloud.com.brightdigit.MistDemo"
        )

        #expect(key.base == "container.identifier")
        #expect(key.defaultValue == "iCloud.com.brightdigit.MistDemo")
    }

    @Test("Create optional config key for web auth token")
    func webAuthTokenKey() {
        let key = OptionalConfigKey<String>(mistDemoPrefixed: "web.auth.token")

        #expect(key.base == "web.auth.token")
    }

    @Test("Create boolean config key for skip auth flag")
    func skipAuthFlagKey() {
        let key = ConfigKey<Bool>(mistDemoPrefixed: "skip.auth", default: false)

        #expect(key.base == "skip.auth")
        #expect(key.defaultValue == false)
    }

    // MARK: - Edge Cases

    @Test("ConfigKey with empty base string")
    func configKeyWithEmptyBase() {
        let key = ConfigKey(mistDemoPrefixed: "", default: "value")

        #expect(key.base == "")
    }

    @Test("ConfigKey with dotted path")
    func configKeyWithDottedPath() {
        let key = ConfigKey(
            mistDemoPrefixed: "cloudkit.api.token",
            default: "default"
        )

        #expect(key.base == "cloudkit.api.token")
    }
}

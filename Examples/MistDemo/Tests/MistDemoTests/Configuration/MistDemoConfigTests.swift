//
//  MistDemoConfigTests.swift
//  MistDemoTests
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
import MistKit
import Testing

@testable import MistDemo

@Suite("MistDemoConfig Tests")
struct MistDemoConfigTests {
  // MARK: - Default Values Tests

  @Test("Config initializes with default values")
  func configInitializesWithDefaults() throws {
    let config = try MistDemoConfig()

    #expect(config.containerIdentifier == "iCloud.com.brightdigit.MistDemo")
    #expect(config.environment == .development)
    #expect(config.host == "127.0.0.1")
    #expect(config.port == 8080)
    #expect(config.skipAuth == false)
    #expect(config.testAllAuth == false)
    #expect(config.testApiOnly == false)
    #expect(config.testAdaptive == false)
    #expect(config.testServerToServer == false)
  }

  // MARK: - Public API Tests

  @Test("Config properties are accessible")
  func configPropertiesAccessible() throws {
    let config = try MistDemoConfig()

    // Verify all properties can be read
    _ = config.containerIdentifier
    _ = config.apiToken
    _ = config.environment
    _ = config.webAuthToken
    _ = config.keyID
    _ = config.privateKey
    _ = config.privateKeyFile
    _ = config.host
    _ = config.port
    _ = config.skipAuth
    _ = config.testAllAuth
    _ = config.testApiOnly
    _ = config.testAdaptive
    _ = config.testServerToServer
  }

  @Test("Resolved API token method exists")
  func resolvedAPITokenMethodExists() throws {
    let config = try MistDemoConfig()
    let token = config.resolvedApiToken()

    // Should return empty string when no token is set
    #expect(token.isEmpty)
  }

  @Test("Resolved web auth token method exists")
  func resolvedWebAuthTokenMethodExists() throws {
    let config = try MistDemoConfig()
    let token = config.resolvedWebAuthToken()

    // Should return nil when no token is set
    #expect(token == nil)
  }

  // MARK: - Environment Tests

  @Test("Development environment is default")
  func developmentEnvironmentIsDefault() throws {
    let config = try MistDemoConfig()
    #expect(config.environment == .development)
  }

  // MARK: - Server Configuration Tests

  @Test("Default host is localhost")
  func defaultHostIsLocalhost() throws {
    let config = try MistDemoConfig()
    #expect(config.host == "127.0.0.1")
  }

  @Test("Default port is 8080")
  func defaultPortIs8080() throws {
    let config = try MistDemoConfig()
    #expect(config.port == 8080)
  }

  // MARK: - Test Flags Tests

  @Test("All test flags default to false")
  func allTestFlagsDefaultToFalse() throws {
    let config = try MistDemoConfig()

    #expect(config.skipAuth == false)
    #expect(config.testAllAuth == false)
    #expect(config.testApiOnly == false)
    #expect(config.testAdaptive == false)
    #expect(config.testServerToServer == false)
  }
}

//
//  CloudKitConfigurationTests.swift
//  CelestraCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

@testable import CelestraCloudKit

@Suite("CloudKitConfiguration Tests")
internal struct CloudKitConfigurationTests {
  @Test("Valid configuration with all fields")
  internal func testValidConfigurationWithAllFields() throws {
    let config = CloudKitConfiguration(
      containerID: "iCloud.com.example.Test",
      keyID: "TEST_KEY_ID",
      privateKeyPath: "/path/to/key.pem",
      environment: .production
    )

    let validated = try config.validated()

    #expect(validated.containerID == "iCloud.com.example.Test")
    #expect(validated.keyID == "TEST_KEY_ID")
    #expect(validated.privateKeyPath == "/path/to/key.pem")
    #expect(validated.environment == .production)
  }

  @Test("Valid configuration with default environment")
  internal func testValidConfigurationWithDefaultEnvironment() throws {
    let config = CloudKitConfiguration(
      containerID: "iCloud.com.example.Test",
      keyID: "TEST_KEY_ID",
      privateKeyPath: "/path/to/key.pem"
    )

    let validated = try config.validated()

    #expect(validated.environment == .development)
  }

  @Test("Missing containerID throws error")
  internal func testMissingContainerIDThrowsError() {
    let config = CloudKitConfiguration(
      containerID: nil,
      keyID: "TEST_KEY_ID",
      privateKeyPath: "/path/to/key.pem"
    )

    #expect(throws: EnhancedConfigurationError.self) {
      try config.validated()
    }
  }

  @Test("Empty containerID throws error with updated message")
  internal func testEmptyContainerIDThrowsError() {
    let config = CloudKitConfiguration(
      containerID: "",
      keyID: "TEST_KEY_ID",
      privateKeyPath: "/path/to/key.pem"
    )

    do {
      _ = try config.validated()
      Issue.record("Expected error to be thrown for empty containerID")
    } catch let error as EnhancedConfigurationError {
      #expect(error.message == "CloudKit container ID must be non-empty")
      #expect(error.key == "cloudkit.container_id")
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Missing keyID throws error")
  internal func testMissingKeyIDThrowsError() {
    let config = CloudKitConfiguration(
      containerID: "iCloud.com.example.Test",
      keyID: nil,
      privateKeyPath: "/path/to/key.pem"
    )

    #expect(throws: EnhancedConfigurationError.self) {
      try config.validated()
    }
  }

  @Test("Empty keyID throws error with updated message")
  internal func testEmptyKeyIDThrowsError() {
    let config = CloudKitConfiguration(
      containerID: "iCloud.com.example.Test",
      keyID: "",
      privateKeyPath: "/path/to/key.pem"
    )

    do {
      _ = try config.validated()
      Issue.record("Expected error to be thrown for empty keyID")
    } catch let error as EnhancedConfigurationError {
      #expect(error.message == "CloudKit key ID must be non-empty")
      #expect(error.key == "cloudkit.key_id")
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Missing privateKeyPath throws error")
  internal func testMissingPrivateKeyPathThrowsError() {
    let config = CloudKitConfiguration(
      containerID: "iCloud.com.example.Test",
      keyID: "TEST_KEY_ID",
      privateKeyPath: nil
    )

    #expect(throws: EnhancedConfigurationError.self) {
      try config.validated()
    }
  }

  @Test("Empty privateKeyPath throws error with updated message")
  internal func testEmptyPrivateKeyPathThrowsError() {
    let config = CloudKitConfiguration(
      containerID: "iCloud.com.example.Test",
      keyID: "TEST_KEY_ID",
      privateKeyPath: ""
    )

    do {
      _ = try config.validated()
      Issue.record("Expected error to be thrown for empty privateKeyPath")
    } catch let error as EnhancedConfigurationError {
      #expect(error.message == "CloudKit private key path must be non-empty")
      #expect(error.key == "cloudkit.private_key_path")
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Environment set to production")
  internal func testEnvironmentSetToProduction() throws {
    let config = CloudKitConfiguration(
      containerID: "iCloud.com.example.Test",
      keyID: "TEST_KEY_ID",
      privateKeyPath: "/path/to/key.pem",
      environment: .production
    )

    let validated = try config.validated()

    #expect(validated.environment == .production)
  }

  @Test("Default container ID constant")
  internal func testDefaultContainerIDConstant() {
    #expect(CloudKitConfiguration.defaultContainerID == "iCloud.com.brightdigit.Celestra")
  }
}

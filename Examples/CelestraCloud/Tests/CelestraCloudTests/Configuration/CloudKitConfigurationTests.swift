//
//  CloudKitConfigurationTests.swift
//  CelestraCloud
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
internal import MistKit
internal import MistKitConfiguration
internal import Testing

@testable import CelestraCloudKit

@Suite("CloudKitConfiguration Tests")
internal struct CloudKitConfigurationTests {
  /// A syntactically valid Server-to-Server key ID: exactly 64 hex characters.
  private static let validKeyID = "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2"

  @Test("Valid configuration with all fields")
  internal func testValidConfigurationWithAllFields() throws {
    let config = CloudKitConfiguration(
      containerID: "iCloud.com.example.Test",
      keyID: Self.validKeyID,
      privateKeyPath: "/path/to/key.pem",
      environment: "production"
    )

    let validated = try config.validatedForCelestra()

    #expect(validated.containerID == "iCloud.com.example.Test")
    #expect(validated.keyID == Self.validKeyID)
    #expect(validated.privateKey.filePath == "/path/to/key.pem")
    #expect(validated.environment == .production)
  }

  @Test("Valid configuration with default environment")
  internal func testValidConfigurationWithDefaultEnvironment() throws {
    let config = CloudKitConfiguration(
      containerID: "iCloud.com.example.Test",
      keyID: Self.validKeyID,
      privateKeyPath: "/path/to/key.pem"
    )

    let validated = try config.validatedForCelestra()

    #expect(validated.environment == .development)
  }

  @Test("Missing containerID throws error")
  internal func testMissingContainerIDThrowsError() {
    let config = CloudKitConfiguration(
      containerID: nil,
      keyID: Self.validKeyID,
      privateKeyPath: "/path/to/key.pem"
    )

    #expect(throws: ConfigurationError.self) {
      try config.validatedForCelestra()
    }
  }

  @Test("Empty containerID throws error with updated message")
  internal func testEmptyContainerIDThrowsError() {
    let config = CloudKitConfiguration(
      containerID: "",
      keyID: Self.validKeyID,
      privateKeyPath: "/path/to/key.pem"
    )

    do {
      _ = try config.validatedForCelestra()
      Issue.record("Expected error to be thrown for empty containerID")
    } catch let error as ConfigurationError {
      #expect(error.message == "CloudKit container ID must be non-empty")
      #expect(error.key == "cloudkit.container-id")
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

    #expect(throws: ConfigurationError.self) {
      try config.validatedForCelestra()
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
      _ = try config.validatedForCelestra()
      Issue.record("Expected error to be thrown for empty keyID")
    } catch let error as ConfigurationError {
      #expect(error.message == "CloudKit key ID must be non-empty")
      #expect(error.key == "cloudkit.key-id")
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Missing privateKeyPath throws error")
  internal func testMissingPrivateKeyPathThrowsError() {
    let config = CloudKitConfiguration(
      containerID: "iCloud.com.example.Test",
      keyID: Self.validKeyID,
      privateKeyPath: nil
    )

    #expect(throws: ConfigurationError.self) {
      try config.validatedForCelestra()
    }
  }

  @Test("Empty privateKeyPath throws error with updated message")
  internal func testEmptyPrivateKeyPathThrowsError() {
    let config = CloudKitConfiguration(
      containerID: "iCloud.com.example.Test",
      keyID: Self.validKeyID,
      privateKeyPath: ""
    )

    do {
      _ = try config.validatedForCelestra()
      Issue.record("Expected error to be thrown for empty privateKeyPath")
    } catch let error as ConfigurationError {
      #expect(
        error.message
          == "Either CLOUDKIT_PRIVATE_KEY or CLOUDKIT_PRIVATE_KEY_PATH must be provided")
      #expect(error.key == "cloudkit.private-key")
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Environment set to production")
  internal func testEnvironmentSetToProduction() throws {
    let config = CloudKitConfiguration(
      containerID: "iCloud.com.example.Test",
      keyID: Self.validKeyID,
      privateKeyPath: "/path/to/key.pem",
      environment: "production"
    )

    let validated = try config.validatedForCelestra()

    #expect(validated.environment == .production)
  }

  @Test("Default container ID constant")
  internal func testDefaultContainerIDConstant() {
    #expect(ConfigurationKeys.defaultContainerID == "iCloud.com.brightdigit.Celestra")
  }
}

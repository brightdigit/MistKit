//
//  CloudKitConfigurationTests.swift
//  MistKitConfiguration
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

internal import MistKit
import Testing

@testable import MistKitConfiguration

@Suite("CloudKitConfiguration.validated")
internal struct CloudKitConfigurationTests {
  private static func complete(
    containerID: String? = "iCloud.com.test.App",
    keyID: String? = TestFixtures.validKeyID,
    privateKeyPath: String? = "/tmp/key.pem",
    privateKey: String? = nil,
    environment: String? = nil
  ) -> CloudKitConfiguration {
    CloudKitConfiguration(
      containerID: containerID,
      keyID: keyID,
      privateKeyPath: privateKeyPath,
      privateKey: privateKey,
      environment: environment
    )
  }

  @Test("Validates a complete configuration")
  internal func validatesComplete() throws {
    let validated = try Self.complete().validated()
    #expect(validated.containerID == "iCloud.com.test.App")
    #expect(validated.keyID == TestFixtures.validKeyID)
    #expect(validated.environment == .development)
  }

  @Test("Missing or empty required fields report the field")
  internal func reportsMissingFields() {
    #expect(throws: CloudKitConfigurationError.missing(.containerID)) {
      try Self.complete(containerID: nil).validated()
    }
    #expect(throws: CloudKitConfigurationError.missing(.containerID)) {
      try Self.complete(containerID: "").validated()
    }
    #expect(throws: CloudKitConfigurationError.missing(.keyID)) {
      try Self.complete(keyID: nil).validated()
    }
    #expect(throws: CloudKitConfigurationError.missing(.privateKey)) {
      try Self.complete(privateKeyPath: nil).validated()
    }
  }

  @Test("An inline private key wins over a path")
  internal func inlineKeyWinsOverPath() throws {
    let validated = try Self.complete(privateKey: TestFixtures.validPEM).validated()
    guard case .raw = validated.privateKey else {
      Issue.record("expected inline PEM to win, got \(validated.privateKey)")
      return
    }
  }

  @Test("Whitespace-only private-key values count as absent")
  internal func whitespaceIsAbsent() {
    #expect(throws: CloudKitConfigurationError.missing(.privateKey)) {
      try Self.complete(privateKeyPath: "   ", privateKey: "  \n ").validated()
    }
  }

  @Test("Environment parses case-insensitively and defaults to development")
  internal func parsesEnvironment() throws {
    #expect(try Self.complete(environment: "production").validated().environment == .production)
    #expect(try Self.complete(environment: "PRODUCTION").validated().environment == .production)
    #expect(try Self.complete(environment: nil).validated().environment == .development)
  }

  @Test("An unrecognized environment is reported verbatim")
  internal func rejectsUnknownEnvironment() {
    #expect(throws: CloudKitConfigurationError.unrecognizedEnvironment("staging")) {
      try Self.complete(environment: "staging").validated()
    }
  }

  @Test("Presence is checked before format")
  internal func presencePrecedesFormat() {
    // Both a malformed key ID and no private key: the missing field is reported first.
    #expect(throws: CloudKitConfigurationError.missing(.privateKey)) {
      try Self.complete(keyID: "not-a-key", privateKeyPath: nil).validated()
    }
  }

  @Test("A malformed key ID surfaces the specific validation failure")
  internal func surfacesKeyIDFailure() {
    #expect(
      throws: CloudKitConfigurationError.invalidKeyID(.incorrectLength(actual: 9))
    ) {
      try Self.complete(keyID: "not-a-key").validated()
    }
  }

  @Test("A malformed inline PEM surfaces the specific validation failure")
  internal func surfacesPEMFailure() {
    #expect(throws: CloudKitConfigurationError.invalidPrivateKey(.missingHeader)) {
      try Self.complete(privateKey: "just some text").validated()
    }
  }
}

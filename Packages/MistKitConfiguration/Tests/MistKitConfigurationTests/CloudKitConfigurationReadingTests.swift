//
//  CloudKitConfigurationReadingTests.swift
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

internal import ConfigKeyKit
internal import Configuration
internal import MistKit
import Testing

@testable import MistKitConfiguration

@Suite("readCloudKitConfiguration")
internal struct CloudKitConfigurationReadingTests {
  private static let keys = CloudKitConfigurationKeys(
    defaultContainerID: "iCloud.com.test.Default"
  )

  /// Builds a reader over the **real** providers with injected inputs, so key
  /// normalization and value coercion behave exactly as they do in production. An
  /// in-memory double matches keys literally and serves only the type it stored, which is
  /// precisely where such doubles drift from the real stack.
  private static func reader(
    arguments: [String] = [],
    environment: [String: String] = [:]
  ) -> ConfigReader {
    ConfigurationSources.makeConfigReader(
      secretCommandLineFlags: keys.secretCommandLineFlags,
      arguments: ["app"] + arguments,
      environmentVariables: environment
    )
  }

  @Test("Falls back to the container default when nothing supplies one")
  internal func containerDefault() {
    let config = Self.reader().readCloudKitConfiguration(keys: Self.keys)
    #expect(config.containerID == "iCloud.com.test.Default")
    #expect(config.keyID == nil)
    #expect(config.environment == nil)
  }

  @Test("Reads from the environment")
  internal func readsEnvironment() {
    let reader = Self.reader(environment: [
      "CLOUDKIT_CONTAINER_ID": "iCloud.com.test.FromEnv",
      "CLOUDKIT_KEY_ID": TestFixtures.validKeyID,
      "CLOUDKIT_ENVIRONMENT": "production",
    ])
    let config = reader.readCloudKitConfiguration(keys: Self.keys)

    #expect(config.containerID == "iCloud.com.test.FromEnv")
    #expect(config.keyID == TestFixtures.validKeyID)
    #expect(config.environment == "production")
  }

  @Test("Command line takes precedence over the environment")
  internal func commandLineWins() {
    let reader = Self.reader(
      arguments: ["--cloudkit-container-id", "iCloud.com.test.FromCLI"],
      environment: ["CLOUDKIT_CONTAINER_ID": "iCloud.com.test.FromEnv"]
    )
    let config = reader.readCloudKitConfiguration(keys: Self.keys)

    #expect(config.containerID == "iCloud.com.test.FromCLI")
  }

  @Test("Reading never throws; an unparseable environment surfaces at validation")
  internal func readingNeverThrows() {
    let reader = Self.reader(environment: [
      "CLOUDKIT_KEY_ID": TestFixtures.validKeyID,
      "CLOUDKIT_PRIVATE_KEY_PATH": "/tmp/key.pem",
      "CLOUDKIT_ENVIRONMENT": "staging",
    ])
    let config = reader.readCloudKitConfiguration(keys: Self.keys)

    #expect(config.environment == "staging")
    #expect(throws: CloudKitConfigurationError.unrecognizedEnvironment("staging")) {
      try config.validated()
    }
  }

  @Test("A full command line validates end to end")
  internal func endToEnd() throws {
    let reader = Self.reader(arguments: [
      "--cloudkit-container-id", "iCloud.com.test.App",
      "--cloudkit-key-id", TestFixtures.validKeyID,
      "--cloudkit-private-key-path", "/tmp/key.pem",
      "--cloudkit-environment", "production",
    ])
    let config = reader.readCloudKitConfiguration(keys: Self.keys)

    let validated = try config.validated()
    #expect(validated.containerID == "iCloud.com.test.App")
    #expect(validated.environment == .production)
  }
}

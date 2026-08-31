//
//  ConfigurationSourcesTests.swift
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

internal import Configuration
import Testing

@testable import MistKitConfiguration

@Suite("ConfigurationSources")
internal struct ConfigurationSourcesTests {
  private static let keys = CloudKitConfigurationKeys(
    defaultContainerID: "iCloud.com.test.App"
  )

  @Test("Command-line arguments outrank environment variables")
  internal func providerOrder() {
    let reader = ConfigurationSources.makeConfigReader(
      secretCommandLineFlags: Self.keys.secretCommandLineFlags,
      arguments: ["app", "--cloudkit-environment", "production"],
      environmentVariables: ["CLOUDKIT_ENVIRONMENT": "development"]
    )
    #expect(reader.readCloudKitConfiguration(keys: Self.keys).environment == "production")
  }

  /// Regression test for the redaction bug this package's derived flag list prevents: a
  /// snake_case key base generated `--cloudkit-key_id`, which never matched the
  /// hand-written `--cloudkit-key-id` in the secrets list, so a private key passed by flag
  /// was logged in the clear.
  @Test("A private key passed by flag is redacted from the provider's description")
  internal func privateKeyIsRedacted() {
    let secret = "-----BEGIN PRIVATE KEY-----SUPERSECRET-----END PRIVATE KEY-----"
    let provider = CommandLineArgumentsProvider(
      arguments: ["app", "--cloudkit-private-key", secret],
      secretsSpecifier: .specific(Self.keys.secretCommandLineFlags)
    )
    let described = String(describing: provider)
    #expect(!described.contains("SUPERSECRET"), "the private key must not appear: \(described)")
  }
}

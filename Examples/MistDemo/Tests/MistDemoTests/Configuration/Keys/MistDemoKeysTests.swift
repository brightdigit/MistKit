//
//  MistDemoKeysTests.swift
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
internal import Configuration
import Testing

@testable import MistDemoKit

/// Pins the wire contract of ``MistDemoKeys``: the environment-variable names CI and the
/// deployment docs rely on, and the command-line flags the README documents.
@Suite("MistDemoKeys")
internal struct MistDemoKeysTests {
  /// The eight variables `MistDemo-Integration.yml` and `docs/cloudkit-guide/` set.
  ///
  /// `CLOUDKIT_CONTAINER_ID` is the one that changed: the old `container.identifier`
  /// base resolved to `CLOUDKIT_CONTAINER_IDENTIFIER`, so the value CI supplied was
  /// silently ignored and every run fell back to the built-in default.
  @Test(
    "Deployment environment variables resolve",
    arguments: [
      (MistDemoKeys.CloudKit.containerID as any ConfigurationKey, "CLOUDKIT_CONTAINER_ID"),
      (MistDemoKeys.CloudKit.keyID, "CLOUDKIT_KEY_ID"),
      (MistDemoKeys.CloudKit.privateKey, "CLOUDKIT_PRIVATE_KEY"),
      (MistDemoKeys.CloudKit.privateKeyPath, "CLOUDKIT_PRIVATE_KEY_PATH"),
      (MistDemoKeys.CloudKit.environment, "CLOUDKIT_ENVIRONMENT"),
      (MistDemoKeys.Auth.apiToken, "CLOUDKIT_API_TOKEN"),
      (MistDemoKeys.Auth.webAuthToken, "CLOUDKIT_WEB_AUTH_TOKEN"),
      (MistDemoKeys.Auth.shareeWebAuthToken, "CLOUDKIT_SHAREE_WEB_AUTH_TOKEN"),
      (MistDemoKeys.Auth.shareeEmail, "CLOUDKIT_SHAREE_EMAIL"),
    ]
  )
  internal func environmentVariableNames(key: any ConfigurationKey, expected: String) throws {
    let resolved = try #require(key.key(for: .environment))
    let normalized = String(resolved.uppercased().map { $0.isLetter || $0.isNumber ? $0 : "_" })
    #expect(normalized == expected)
  }

  /// Every credential key must be dash-case, never snake_case: `CLIKeyEncoder` joins key
  /// components verbatim, so an underscore survives into an unusable flag and silently
  /// defeats secret redaction.
  @Test("Credential key bases are dash-case")
  internal func basesAreDashCase() {
    let bases = [
      MistDemoKeys.CloudKit.containerID.base,
      MistDemoKeys.CloudKit.keyID.base,
      MistDemoKeys.CloudKit.privateKey.base,
      MistDemoKeys.CloudKit.privateKeyPath.base,
      MistDemoKeys.CloudKit.environment.base,
    ]
    for base in bases {
      let unwrapped = base ?? ""
      #expect(!unwrapped.contains("_"), "\(unwrapped) must not contain an underscore")
      #expect(unwrapped.hasPrefix("cloudkit."), "\(unwrapped) must be cloudkit-namespaced")
    }
  }

  /// The three credential keys carry `isSecret`, so a value passed by flag is redacted.
  @Test("Credential keys are marked secret")
  internal func credentialKeysAreSecret() {
    #expect(MistDemoKeys.CloudKit.keyID.isSecret)
    #expect(MistDemoKeys.CloudKit.privateKey.isSecret)
    #expect(MistDemoKeys.CloudKit.privateKeyPath.isSecret)
    #expect(MistDemoKeys.Auth.apiToken.isSecret)
    #expect(MistDemoKeys.Auth.webAuthToken.isSecret)
  }
}

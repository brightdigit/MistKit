//
//  CloudKitConfigurationKeysTests.swift
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
import Testing

@testable import MistKitConfiguration

@Suite("CloudKitConfigurationKeys")
internal struct CloudKitConfigurationKeysTests {
  private static let keys = CloudKitConfigurationKeys(
    defaultContainerID: "iCloud.com.test.App"
  )

  @Test("Bases are dash-case and cloudkit-namespaced")
  internal func basesAreDashCase() {
    let bases = CloudKitConfigurationField.allCases.compactMap {
      Self.keys[$0].key(for: .commandLine)
    }
    #expect(bases.count == CloudKitConfigurationField.allCases.count)
    for base in bases {
      #expect(!base.contains("_"), "\(base) must not contain an underscore")
      #expect(base.hasPrefix("cloudkit."), "\(base) must be cloudkit-namespaced")
    }
  }

  @Test("Command-line flags are dash-joined")
  internal func commandLineFlags() {
    #expect(Self.keys.keyID.key(for: .commandLine) == "cloudkit.key-id")
    #expect(Self.keys.privateKeyPath.key(for: .commandLine) == "cloudkit.private-key-path")
  }

  @Test("Environment names ignore envPrefix when none is given")
  internal func environmentNamesWithoutPrefix() {
    #expect(Self.keys.keyID.key(for: .environment) == "CLOUDKIT_KEY-ID")
    #expect(Self.keys.containerID.key(for: .environment) == "CLOUDKIT_CONTAINER-ID")
  }

  @Test("envPrefix applies to the environment only, never the command line")
  internal func envPrefixIsEnvironmentOnly() {
    let prefixed = CloudKitConfigurationKeys(
      defaultContainerID: "iCloud.com.test.App",
      envPrefix: "BUSHEL"
    )
    #expect(prefixed.keyID.key(for: .environment) == "BUSHEL_CLOUDKIT_KEY-ID")
    #expect(prefixed.keyID.key(for: .commandLine) == "cloudkit.key-id")
  }

  @Test("The three credential keys are secret; the other two are not")
  internal func secrecy() {
    #expect(Self.keys.keyID.isSecret)
    #expect(Self.keys.privateKey.isSecret)
    #expect(Self.keys.privateKeyPath.isSecret)
    #expect(!Self.keys.containerID.isSecret)
    #expect(!Self.keys.environment.isSecret)
  }

  @Test("The redaction list is derived from isSecret, so it cannot drift")
  internal func secretFlagsAreDerived() {
    #expect(
      Self.keys.secretCommandLineFlags == [
        "--cloudkit-key-id", "--cloudkit-private-key", "--cloudkit-private-key-path",
      ]
    )
  }

  @Test("The container default is the one supplied")
  internal func containerDefault() {
    #expect(Self.keys.containerID.defaultValue == "iCloud.com.test.App")
  }

  @Test("Every field maps to its key")
  internal func fieldSubscript() {
    #expect(Self.keys[.keyID].key(for: .commandLine) == "cloudkit.key-id")
    #expect(Self.keys[.environment].key(for: .commandLine) == "cloudkit.environment")
  }
}

//
//  CloudKitConfigurationKeys.swift
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

public import ConfigKeyKit

/// The five CloudKit configuration keys, parameterized per application.
///
/// A value type rather than a `static` enum because the container default and the
/// environment prefix differ per application, and a `static` member cannot take
/// arguments.
///
/// Bases are **dash-case** (`cloudkit.key-id`, never `cloudkit.key_id`): swift-configuration's
/// `CLIKeyEncoder` joins key components verbatim, so an underscore survives into an
/// unusable flag *and* silently defeats secret redaction, because the redaction list is
/// matched against the generated flag. Build keys only through this type.
public struct CloudKitConfigurationKeys: Sendable {
  /// `cloudkit.container-id`, defaulting to the application's own container.
  public let containerID: ConfigKey<String>
  /// `cloudkit.key-id` — secret.
  public let keyID: OptionalConfigKey<String>
  /// `cloudkit.private-key-path` — secret.
  public let privateKeyPath: OptionalConfigKey<String>
  /// `cloudkit.private-key` — secret.
  public let privateKey: OptionalConfigKey<String>
  /// `cloudkit.environment`.
  public let environment: OptionalConfigKey<String>

  /// The command-line flags whose values must be redacted from logs.
  ///
  /// Derived from each key's `isSecret` rather than hand-listed, so the list cannot drift
  /// from the keys themselves — the drift that previously let a private key passed by
  /// flag be logged in the clear. Splice in application-specific flags with
  /// `union(_:)` before handing the result to
  /// `CommandLineArgumentsProvider(secretsSpecifier: .specific(_:))`.
  public var secretCommandLineFlags: Set<String> {
    let all: [any ConfigurationKey] = [
      containerID, keyID, privateKeyPath, privateKey, environment,
    ]
    return Set(all.filter(\.isSecret).compactMap(Self.commandLineFlag(for:)))
  }

  /// Creates the key group.
  ///
  /// - Parameters:
  ///   - defaultContainerID: Container used when neither the command line nor the
  ///     environment supplies one.
  ///   - envPrefix: Prefix applied to environment-variable names only, e.g. `"BUSHEL"`
  ///     yields `BUSHEL_CLOUDKIT_KEY_ID`. Command-line flags are unaffected. Defaults to
  ///     `nil`, which is what every current consumer uses.
  public init(defaultContainerID: String, envPrefix: String? = nil) {
    self.containerID = ConfigKey<String>(
      "cloudkit.container-id",
      envPrefix: envPrefix,
      default: defaultContainerID
    )
    self.keyID = OptionalConfigKey<String>(
      "cloudkit.key-id",
      envPrefix: envPrefix,
      isSecret: true
    )
    self.privateKeyPath = OptionalConfigKey<String>(
      "cloudkit.private-key-path",
      envPrefix: envPrefix,
      isSecret: true
    )
    self.privateKey = OptionalConfigKey<String>(
      "cloudkit.private-key",
      envPrefix: envPrefix,
      isSecret: true
    )
    self.environment = OptionalConfigKey<String>(
      "cloudkit.environment",
      envPrefix: envPrefix
    )
  }

  private static func commandLineFlag(for key: any ConfigurationKey) -> String? {
    guard let base = key.key(for: .commandLine) else {
      return nil
    }
    return "--" + base.split(separator: ".").joined(separator: "-")
  }

  /// Looks up the key backing a given field.
  ///
  /// Lets an application turn a ``CloudKitConfigurationError`` into a message naming the
  /// flag or variable *it* uses, without hard-coding key strings.
  public subscript(field: CloudKitConfigurationField) -> any ConfigurationKey {
    switch field {
    case .containerID: return containerID
    case .keyID: return keyID
    case .privateKey: return privateKey
    case .privateKeyPath: return privateKeyPath
    case .environment: return environment
    }
  }
}

//
//  MistDemoConfiguration+Testing.swift
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

@testable import MistDemoKit

extension MistDemoConfiguration {
  /// Builds a configuration over the **real** environment provider, keyed by each key's
  /// own resolved environment-variable name.
  ///
  /// Takes typed keys rather than key-path strings so a rename cannot silently
  /// desynchronise the tests from production — the previous string-keyed double seeded
  /// `private.key.file`, which production never read, and nobody noticed.
  ///
  /// Deliberately not `InMemoryProvider`: it matches keys literally and serves only the
  /// type it stored, so it diverged from production on key normalization and on
  /// numeric/boolean coercion.
  internal static func forTesting(
    _ values: [(key: any ConfigurationKey, value: String)]
  ) -> MistDemoConfiguration {
    var environment: [String: String] = [:]
    for entry in values {
      guard let name = entry.key.key(for: .environment) else { continue }
      environment[Self.environmentVariableName(name)] = entry.value
    }
    return MistDemoConfiguration(
      configReader: ConfigReader(
        providers: [EnvironmentVariablesProvider(environmentVariables: environment)]
      )
    )
  }

  /// Applies the same normalization swift-configuration's `EnvironmentKeyEncoder` does.
  ///
  /// ConfigKeyKit's `screamingSnakeCase` only maps `.` to `_`, so a dash-case base such
  /// as `cloudkit.container-id` yields `CLOUDKIT_CONTAINER-ID`. In production that string
  /// is handed to the reader, whose encoder then maps every non-alphanumeric to `_` and
  /// arrives at `CLOUDKIT_CONTAINER_ID`. Seeding a provider directly skips that step, so
  /// it has to be reproduced here or the variable never matches.
  private static func environmentVariableName(_ resolved: String) -> String {
    String(
      resolved.uppercased().map { $0.isLetter || $0.isNumber ? $0 : "_" }
    )
  }
}

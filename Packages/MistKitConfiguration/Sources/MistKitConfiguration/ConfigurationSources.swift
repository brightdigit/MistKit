//
//  ConfigurationSources.swift
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

public import Configuration

/// The provider stack this package expects: command-line arguments first, then
/// environment variables.
///
/// Captures the one piece of loader wiring that is genuinely shared — provider order plus
/// the redaction list — without owning the application-shaped parts. Each application
/// keeps its own loader and its own root configuration type.
public enum ConfigurationSources {
  /// Builds a reader over the current process's arguments and environment.
  ///
  /// - Parameter secretCommandLineFlags: Flags whose values must be redacted; pass
  ///   ``CloudKitConfigurationKeys/secretCommandLineFlags``, unioned with any of your own.
  /// - Returns: A reader over the command line and the process environment.
  public static func makeConfigReader(
    secretCommandLineFlags: Set<String>
  ) -> ConfigReader {
    ConfigReader(providers: [
      CommandLineArgumentsProvider(
        secretsSpecifier: .specific(secretCommandLineFlags)
      ),
      EnvironmentVariablesProvider(),
    ])
  }

  /// Builds a reader over injected arguments and environment.
  ///
  /// Use from tests: driving the real providers means key normalization and value
  /// coercion behave exactly as they do in production, which an in-memory double does not
  /// guarantee.
  ///
  /// - Parameters:
  ///   - secretCommandLineFlags: Flags whose values must be redacted.
  ///   - arguments: A full argument vector, including the executable name at index 0.
  ///   - environmentVariables: The simulated environment.
  /// - Returns: A reader over the injected arguments and environment.
  public static func makeConfigReader(
    secretCommandLineFlags: Set<String>,
    arguments: [String],
    environmentVariables: [String: String]
  ) -> ConfigReader {
    ConfigReader(providers: [
      CommandLineArgumentsProvider(
        arguments: arguments,
        secretsSpecifier: .specific(secretCommandLineFlags)
      ),
      EnvironmentVariablesProvider(environmentVariables: environmentVariables),
    ])
  }
}

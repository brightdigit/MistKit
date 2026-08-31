//
//  ConfigurationLoader.swift
//  BushelCloud
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
internal import Foundation

/// Actor responsible for loading configuration from CLI arguments and environment variables
public actor ConfigurationLoader {
  internal let configReader: ConfigReader

  /// Initialize the configuration loader with command-line and environment providers
  public init() {
    var providers: [any ConfigProvider] = []

    // Priority 1: Command-line arguments (automatically parses all --key value and --flag arguments)
    providers.append(
      CommandLineArgumentsProvider(
        secretsSpecifier: .specific([
          "--cloudkit-key-id",
          "--cloudkit-private-key-path",
          "--cloudkit-private-key",
          "--virtualbuddy-api-key",
        ])
      )
    )

    // Priority 2: Environment variables
    providers.append(EnvironmentVariablesProvider())

    self.configReader = ConfigReader(providers: providers)
  }

  /// Creates a loader over a pre-configured reader.
  ///
  /// Lets tests inject controlled configuration sources instead of mutating
  /// process-global state (environment variables).
  /// - Parameter configReader: Pre-configured reader to read from.
  internal init(configReader: ConfigReader) {
    self.configReader = configReader
  }

}

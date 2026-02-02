//
//  ConfigKey+Bool.swift
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

import Foundation

// MARK: - Specialized Initializers for Booleans

extension ConfigKey where Value == Bool {
  /// Non-optional default value accessor for booleans
  @available(*, deprecated, message: "Use defaultValue directly instead")
  public var boolDefault: Bool {
    defaultValue  // Already non-optional!
  }

  /// Initialize a boolean configuration key with non-optional default
  /// - Parameters:
  ///   - cli: Command-line argument name
  ///   - env: Environment variable name
  ///   - defaultVal: Default value (defaults to false)
  public init(cli: String, env: String, default defaultVal: Bool = false) {
    self.baseKey = nil
    self.styles = [:]
    var keys: [ConfigKeySource: String] = [:]
    keys[.commandLine] = cli
    keys[.environment] = env
    self.explicitKeys = keys
    self.defaultValue = defaultVal
  }

  /// Initialize a boolean configuration key from base string
  /// - Parameters:
  ///   - base: Base key string (e.g., "sync.verbose")
  ///   - envPrefix: Prefix for environment variable (defaults to nil)
  ///   - defaultVal: Default value (defaults to false)
  public init(_ base: String, envPrefix: String? = nil, default defaultVal: Bool = false) {
    self.baseKey = base
    self.styles = [
      .commandLine: StandardNamingStyle.dotSeparated,
      .environment: StandardNamingStyle.screamingSnakeCase(prefix: envPrefix),
    ]
    self.explicitKeys = [:]
    self.defaultValue = defaultVal
  }
}

// Application-specific boolean key helpers should be added in application code
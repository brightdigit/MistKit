//
//  ConfigKey+BUSHEL.swift
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

public import ConfigKeyKit

// MARK: - BushelCloud-Specific Config Key Helpers

extension ConfigKey {
  /// Convenience initializer for keys with `BUSHEL_` environment-variable prefix.
  /// - Parameters:
  ///   - base: Base key string (e.g., "sync.dry_run")
  ///   - defaultVal: Required default value
  public init(bushelPrefixed base: String, default defaultVal: Value) {
    self.init(base, envPrefix: "BUSHEL", default: defaultVal)
  }
}

extension ConfigKey where Value == Bool {
  /// Convenience initializer for boolean keys with `BUSHEL_` environment-variable prefix.
  /// - Parameters:
  ///   - base: Base key string (e.g., "sync.verbose")
  ///   - defaultVal: Default value (defaults to false)
  public init(bushelPrefixed base: String, default defaultVal: Bool = false) {
    self.init(base, envPrefix: "BUSHEL", default: defaultVal)
  }
}

extension OptionalConfigKey {
  /// Convenience initializer for optional keys with `BUSHEL_` environment-variable prefix.
  /// - Parameter base: Base key string (e.g., "sync.min_interval")
  public init(bushelPrefixed base: String) {
    self.init(base, envPrefix: "BUSHEL")
  }
}

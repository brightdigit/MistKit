//
//  MistDemoConfiguration.swift
//  ConfigKeyKit
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

import Configuration
import Foundation

/// Swift Configuration-based setup for MistDemo
public struct MistDemoConfiguration: Sendable {
  // MARK: Lifecycle

  public init() throws {
    self.configReader = ConfigReader(providers: [
      // 1. Environment variables (highest priority for now)
      EnvironmentVariablesProvider(),
      
      // 2. In-memory defaults (lowest priority)
      InMemoryProvider(values: [
        "port": 8080,
        "skip.auth": false,
        "test.all.auth": false,
        "test.api.only": false,
        "test.adaptive": false,
        "test.server.to.server": false
      ])
    ])
  }

  // MARK: Private

  private let configReader: ConfigReader

  /// Read string value with hierarchy: CLI → ENV → defaults
  public func string(
    forKey key: String,
    default defaultValue: String? = nil,
    isSecret: Bool = false
  ) -> String? {
    if let defaultValue = defaultValue {
      return configReader.string(forKey: Configuration.ConfigKey(key), isSecret: isSecret, default: defaultValue)
    } else {
      return configReader.string(forKey: Configuration.ConfigKey(key), isSecret: isSecret)
    }
  }

  /// Read required string value
  public func requiredString(
    forKey key: String,
    isSecret: Bool = false
  ) throws -> String {
    try configReader.requiredString(forKey: Configuration.ConfigKey(key), isSecret: isSecret)
  }

  /// Read int value with hierarchy
  public func int(
    forKey key: String,
    default defaultValue: Int? = nil
  ) -> Int? {
    if let defaultValue = defaultValue {
      return configReader.int(forKey: Configuration.ConfigKey(key), default: defaultValue)
    } else {
      return configReader.int(forKey: Configuration.ConfigKey(key))
    }
  }

  /// Read required int value
  public func requiredInt(forKey key: String) throws -> Int {
    try configReader.requiredInt(forKey: Configuration.ConfigKey(key))
  }

  /// Read bool value with hierarchy
  public func bool(
    forKey key: String,
    default defaultValue: Bool = false
  ) -> Bool {
    configReader.bool(forKey: Configuration.ConfigKey(key), default: defaultValue)
  }

}
//
//  ConfigKey+MistDemo.swift
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

public import ConfigKeyKit
import Foundation

// MARK: - MistDemo-Specific Config Key Helpers

extension ConfigKey {
    /// Convenience initializer for keys with MISTDEMO prefix
    /// - Parameters:
    ///   - base: Base key string (e.g., "cloudkit.container.id")
    ///   - defaultVal: Required default value
    public init(mistDemoPrefixed base: String, default defaultVal: Value) {
        self.init(base, envPrefix: "MISTDEMO", default: defaultVal)
    }
}

extension OptionalConfigKey {
    /// Convenience initializer for keys with MISTDEMO prefix
    /// - Parameter base: Base key string (e.g., "api.token")
    public init(mistDemoPrefixed base: String) {
        self.init(base, envPrefix: "MISTDEMO")
    }
}

extension ConfigKey where Value == Bool {
    /// Convenience initializer for boolean keys with MISTDEMO prefix
    /// - Parameters:
    ///   - base: Base key string (e.g., "debug.enabled")
    ///   - defaultVal: Default value (defaults to false)
    public init(mistDemoPrefixed base: String, default defaultVal: Bool = false) {
        self.init(base, envPrefix: "MISTDEMO", default: defaultVal)
    }
}

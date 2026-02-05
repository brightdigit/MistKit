//
//  ConfigurationParseable.swift
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

import Foundation

/// Protocol for configuration types that can parse themselves from command line arguments and environment variables
public protocol ConfigurationParseable: Sendable {
    /// Associated type for the configuration reader
    associatedtype ConfigReader: Sendable

    /// Associated type for the parent configuration
    /// Use `Never` for root configurations that have no parent
    associatedtype BaseConfig: Sendable

    /// Initialize the configuration by parsing from available sources (CLI args, environment variables, defaults)
    /// - Parameters:
    ///   - configuration: The configuration reader to parse values from
    ///   - base: Optional parent configuration (nil for root configs)
    init(configuration: ConfigReader, base: BaseConfig?) async throws
}

/// Extension for root configurations (where BaseConfig == Never)
public extension ConfigurationParseable where BaseConfig == Never {
    /// Convenience initializer for root configs that don't need a parent
    init(configuration: ConfigReader) async throws {
        try await self.init(configuration: configuration, base: nil)
    }
}
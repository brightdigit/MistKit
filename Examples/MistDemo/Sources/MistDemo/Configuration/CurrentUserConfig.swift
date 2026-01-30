//
//  CurrentUserConfig.swift
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

public import Foundation
public import MistKit
public import ConfigKeyKit

/// Configuration for current-user command
public struct CurrentUserConfig: Sendable, ConfigurationParseable {
    public typealias ConfigReader = MistDemoConfiguration
    public typealias BaseConfig = MistDemoConfig

    public let base: MistDemoConfig
    public let fields: [String]?
    public let output: OutputFormat

    public init(base: MistDemoConfig, fields: [String]? = nil, output: OutputFormat = .json) {
        self.base = base
        self.fields = fields
        self.output = output
    }

    /// Parse configuration from command line arguments
    public init(configuration: MistDemoConfiguration, base: MistDemoConfig?) async throws {
        let configReader = configuration
        let baseConfig = try await base ?? MistDemoConfig(configuration: configuration, base: nil)
        
        // Parse fields filter
        let fieldsString = configReader.string(forKey: "fields")
        let fields = fieldsString?.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        
        // Parse output format
        let outputString = configReader.string(forKey: "output.format", default: "json") ?? "json"
        let output = OutputFormat(rawValue: outputString) ?? .json
        
        self.init(
            base: baseConfig,
            fields: fields,
            output: output
        )
    }
}
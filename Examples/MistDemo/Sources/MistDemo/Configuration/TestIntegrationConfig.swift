//
//  TestIntegrationConfig.swift
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
public import MistKit

/// Configuration for test-integration command
public struct TestIntegrationConfig: Sendable, ConfigurationParseable {
    public typealias ConfigReader = MistDemoConfiguration
    public typealias BaseConfig = MistDemoConfig

    public let base: MistDemoConfig
    public let database: MistKit.Database
    public let recordCount: Int
    public let assetSizeKB: Int
    public let skipCleanup: Bool
    public let verbose: Bool

    public init(
        base: MistDemoConfig,
        database: MistKit.Database = .public,
        recordCount: Int = 10,
        assetSizeKB: Int = 100,
        skipCleanup: Bool = false,
        verbose: Bool = false
    ) {
        self.base = base
        self.database = database
        self.recordCount = recordCount
        self.assetSizeKB = assetSizeKB
        self.skipCleanup = skipCleanup
        self.verbose = verbose
    }

    /// Parse configuration from command line arguments
    public init(configuration: MistDemoConfiguration, base: MistDemoConfig?) async throws {
        let baseConfig: MistDemoConfig
        if let base {
            baseConfig = base
        } else {
            baseConfig = try await MistDemoConfig(configuration: configuration, base: nil)
        }

        let databaseString = configuration.string(forKey: "database", default: "public") ?? "public"
        guard let database = MistKit.Database(rawValue: databaseString) else {
            throw ConfigurationError.invalidDatabase(databaseString)
        }
        let recordCount = configuration.int(forKey: "record.count", default: 10) ?? 10
        let assetSizeKB = configuration.int(forKey: "asset.size", default: 100) ?? 100
        let skipCleanup = configuration.bool(forKey: "skip.cleanup", default: false)
        let verbose = configuration.bool(forKey: "verbose", default: false)

        self.init(
            base: baseConfig,
            database: database,
            recordCount: recordCount,
            assetSizeKB: assetSizeKB,
            skipCleanup: skipCleanup,
            verbose: verbose
        )
    }
}

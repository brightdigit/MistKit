//
//  TestIntegrationCommand.swift
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
import MistKit

/// Command to run comprehensive integration tests for all CloudKit operations
public struct TestIntegrationCommand: MistDemoCommand {
    public typealias Config = TestIntegrationConfig
    public static let commandName = "test-integration"
    public static let abstract = "Run comprehensive integration tests for all CloudKit operations"
    public static let helpText = """
        TEST-INTEGRATION - Run comprehensive integration tests

        USAGE:
            mistdemo test-integration [options]

        OPTIONS:
            --database <type>          Database to use: public, private (default: "private")
            --record-count <count>     Number of test records to create (default: 10)
            --asset-size <kb>          Asset size for test in KB (default: 100)
            --skip-cleanup             Skip cleanup after integration test
            --verbose                  Run in verbose mode

        EXAMPLES:
            # Run default integration tests
            mistdemo test-integration

            # Run with custom settings
            mistdemo test-integration --record-count 5 --asset-size 50 --verbose

            # Run without cleanup for debugging
            mistdemo test-integration --skip-cleanup --verbose

        NOTES:
            - Requires web auth token for private database access
            - Set CLOUDKIT_WEB_AUTH_TOKEN or use 'auth-token' command first
        """

    private let config: TestIntegrationConfig

    public init(config: TestIntegrationConfig) {
        self.config = config
    }

    public func execute() async throws {
        let runner = IntegrationTestRunner(
            containerIdentifier: config.base.containerIdentifier,
            apiToken: config.base.apiToken,
            webAuthToken: config.base.webAuthToken ?? "",
            environment: config.base.environment,
            database: config.database,
            recordCount: config.recordCount,
            assetSizeKB: config.assetSizeKB,
            skipCleanup: config.skipCleanup,
            verbose: config.verbose
        )

        try await runner.runBasicWorkflow()
    }
}

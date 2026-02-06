//
//  TestIntegration.swift
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

import ArgumentParser
import Foundation
import MistKit

/// Run comprehensive integration tests for all CloudKit operations
struct TestIntegration: AsyncParsableCommand, CloudKitCommand {
    static let configuration = CommandConfiguration(
        commandName: "test-integration",
        abstract: "Run comprehensive integration tests for all CloudKit operations"
    )

    @Option(name: .shortAndLong, help: "CloudKit container identifier")
    var containerIdentifier: String = "iCloud.com.brightdigit.MistDemo"

    @Option(name: .shortAndLong, help: "CloudKit API token")
    var apiToken: String = ""

    @Option(name: .long, help: "Environment (development or production)")
    var environment: String = "development"

    @Option(name: .long, help: "Database to use (public or private)")
    var database: String = "private"

    @Option(name: .long, help: "Web auth token for private database access")
    var webAuthToken: String = ""

    @Option(name: .long, help: "Number of test records to create (default: 10)")
    var recordCount: Int = 10

    @Option(name: .long, help: "Asset size for integration test in KB (default: 100)")
    var assetSize: Int = 100

    @Flag(name: .long, help: "Skip cleanup after integration test")
    var skipCleanup: Bool = false

    @Flag(name: .long, help: "Run integration test in verbose mode")
    var verbose: Bool = false

    func run() async throws {
        let resolvedToken = resolvedApiToken()

        guard !resolvedToken.isEmpty else {
            print("❌ Error: CloudKit API token is required")
            print("   Provide it via --api-token or set CLOUDKIT_API_TOKEN environment variable")
            print("   Get your API token from: https://icloud.developer.apple.com/dashboard/")
            return
        }

        // Resolve web auth token from option or environment variable
        let resolvedWebAuthToken = webAuthToken.isEmpty ?
            ProcessInfo.processInfo.environment["CLOUDKIT_WEBAUTH_TOKEN"] ?? "" :
            webAuthToken

        // Check if web auth token is required for private database
        if database == "private" && resolvedWebAuthToken.isEmpty {
            print("❌ Error: Web auth token is required for private database access")
            print("   Provide it via --web-auth-token or set CLOUDKIT_WEBAUTH_TOKEN environment variable")
            print("   Use the 'auth' command to authenticate and get a web auth token")
            return
        }

        let cloudKitDatabase: MistKit.Database = database == "public" ? .public : .private

        let runner = IntegrationTestRunner(
            containerIdentifier: containerIdentifier,
            apiToken: resolvedToken,
            webAuthToken: resolvedWebAuthToken,
            environment: cloudKitEnvironment(),
            database: cloudKitDatabase,
            recordCount: recordCount,
            assetSizeKB: assetSize,
            skipCleanup: skipCleanup,
            verbose: verbose
        )

        try await runner.runBasicWorkflow()
    }
}

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
    TEST-INTEGRATION - Run comprehensive integration tests (public database)

    Tests all non-user-scoped CloudKit API methods against the public database.
    Use 'test-private' to also test user-identity APIs (requires web auth token).

    USAGE:
        mistdemo test-integration [options]

    OPTIONS:
        --database <type>          Database to use: public, private (default: "public")
        --record-count <count>     Number of test records to create (default: 10)
        --asset-size <kb>          Asset size for test in KB (default: 100)
        --skip-cleanup             Skip cleanup after integration test
        --verbose                  Run in verbose mode

    PHASES:
        1.  Lookup default zone     (lookupZones)
        2.  Upload test asset       (uploadAssets)
        3.  Create records          (createRecord)
        4.  Query records by type   (queryRecords)
        5.  Lookup records by name  (lookupRecords)
        6.  Modify records          (updateRecord)
        7.  Final zone check        (lookupZones)
        8.  Cleanup                 (deleteRecord)

    EXAMPLES:
        # Run with server-to-server auth (public database)
        mistdemo test-integration --verbose

        # Run without cleanup for debugging
        mistdemo test-integration --skip-cleanup --verbose

    NOTES:
        - Requires CLOUDKIT_KEY_ID and CLOUDKIT_PRIVATE_KEY for public database
        - For user-identity API coverage, use 'mistdemo test-private' instead
    """

  private let config: TestIntegrationConfig

  public init(config: TestIntegrationConfig) {
    self.config = config
  }

  public func execute() async throws {
    let service = try MistKitClientFactory.create(for: config.base)

    let runner = IntegrationTestRunner(
      service: service,
      containerIdentifier: config.base.containerIdentifier,
      database: config.base.database,
      recordCount: config.recordCount,
      assetSizeKB: config.assetSizeKB,
      skipCleanup: config.skipCleanup,
      verbose: config.verbose
    )

    try await runner.runBasicWorkflow()
  }
}

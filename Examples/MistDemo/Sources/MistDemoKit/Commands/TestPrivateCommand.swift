//
//  TestPrivateCommand.swift
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

/// Command to run comprehensive integration tests against the private database,
/// covering all CloudKit API methods including user-identity endpoints.
public struct TestPrivateCommand: MistDemoCommand {
  public typealias Config = TestPrivateConfig
  public static let commandName = "test-private"
  public static let abstract =
    "Run comprehensive integration tests for private database (all API methods)"
  public static let helpText = """
    TEST-PRIVATE - Run comprehensive integration tests (private database)

    Tests all CloudKit API methods including user-identity endpoints that
    require private database access and web authentication.

    USAGE:
        mistdemo test-private [options]

    OPTIONS:
        --record-count <count>     Number of test records to create (default: 10)
        --asset-size <kb>          Asset size for test in KB (default: 100)
        --skip-cleanup             Skip cleanup after integration test
        --verbose                  Run in verbose mode

    PHASES:
        1.  List all zones                  (listZones)
        2.  Lookup default zone             (lookupZones)
        3.  Fetch zone changes              (fetchZoneChanges)
        4.  Upload test asset               (uploadAssets)
        5.  Create records                  (createRecord)
        6.  Query records by type           (queryRecords)
        7.  Lookup records by name          (lookupRecords)
        8.  Initial sync                    (fetchRecordChanges)
        9.  Modify records                  (updateRecord)
        10. Incremental sync                (fetchRecordChanges with token)
        11. Final zone check                (lookupZones)
        12. Cleanup                         (deleteRecord)
        13. Fetch current user              (fetchCurrentUser)
        14. Discover user identities        (discoverUserIdentities)

    EXAMPLES:
        # Run all private database tests
        mistdemo test-private --verbose

        # Run without cleanup for debugging
        mistdemo test-private --skip-cleanup --verbose

    NOTES:
        - Requires CLOUDKIT_API_TOKEN and CLOUDKIT_WEB_AUTH_TOKEN
        - Run 'mistdemo auth-token' to obtain a web auth token
        - For public-database-only tests, use 'mistdemo test-integration'
    """

  private let config: TestPrivateConfig

  public init(config: TestPrivateConfig) {
    self.config = config
  }

  public func execute() async throws {
    let service = try MistKitClientFactory.create(for: config.base)

    let runner = IntegrationTestRunner(
      service: service,
      containerIdentifier: config.base.containerIdentifier,
      database: .private,
      recordCount: config.recordCount,
      assetSizeKB: config.assetSizeKB,
      skipCleanup: config.skipCleanup,
      verbose: config.verbose
    )

    try await runner.runPrivateWorkflow()
  }
}

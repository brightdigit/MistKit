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
  /// The configuration type.
  public typealias Config = TestIntegrationConfig
  /// The command name.
  public static let commandName = "test-integration"
  /// The command abstract.
  public static let abstract =
    "Run integration tests for all CloudKit operations"
  /// The command help text.
  public static let helpText = """
    TEST-INTEGRATION - Integration tests (public database)

    Tests all non-user-scoped CloudKit API methods against
    the public database. Use 'test-private' for user APIs.

    USAGE:
      mistdemo test-integration [options]

    OPTIONS:
      --database <type>        Database (default: public)
      --record-count <count>   Test records (default: 10)
      --asset-size <kb>        Asset size in KB (default: 100)
      --skip-cleanup           Skip cleanup after test
      --verbose                Run in verbose mode
      --lookup-email <email>   Email for users/lookup/email phase
                               (CLOUDKIT_LOOKUP_EMAIL); must belong
                               to an iCloud account discoverable to
                               the caller, otherwise the phase skips

    EXAMPLES:
      mistdemo test-integration --verbose
      mistdemo test-integration --skip-cleanup --verbose
      mistdemo test-integration --lookup-email me@example.com

    NOTES:
      - Requires CLOUDKIT_KEY_ID and CLOUDKIT_PRIVATE_KEY
      - Use 'test-private' for user-identity coverage
    """

  private let config: TestIntegrationConfig

  /// Creates a new instance.
  public init(config: TestIntegrationConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    let service = try MistKitClientFactory.create(for: config.base)
    // A single service handles every phase: server-to-server signing on
    // `.public` for record ops, plus web-auth for user-identity routes when
    // the API/web-auth env vars are populated. The resolver picks the right
    // token manager per call.
    let supportsUserContextPhases = config.base.hasUserContextCredentials

    let runner = IntegrationTestRunner(
      service: service,
      supportsUserContextPhases: supportsUserContextPhases,
      containerIdentifier: config.base.containerIdentifier,
      database: config.base.database,
      recordCount: config.recordCount,
      assetSizeKB: config.assetSizeKB,
      skipCleanup: config.skipCleanup,
      verbose: config.verbose,
      lookupEmail: config.lookupEmail
    )

    try await runner.runBasicWorkflow()
  }
}

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
  /// The configuration type.
  public typealias Config = TestPrivateConfig
  /// The command name.
  public static let commandName = "test-private"
  /// The command abstract.
  public static let abstract =
    "Run integration tests for private database"
  /// The command help text.
  public static let helpText = """
    TEST-PRIVATE - Integration tests (private database)

    Tests all CloudKit API methods including user-identity
    endpoints requiring private database access.

    USAGE:
      mistdemo test-private [options]

    OPTIONS:
      --record-count <count>   Test records (default: 10)
      --asset-size <kb>        Asset size in KB (default: 100)
      --skip-cleanup           Skip cleanup after test
      --verbose                Run in verbose mode
      --lookup-email <email>
        Email for users/lookup/email phase (CLOUDKIT_LOOKUP_EMAIL).
        Must belong to an iCloud account discoverable to the caller,
        otherwise the phase skips.

    EXAMPLES:
      mistdemo test-private --verbose
      mistdemo test-private --skip-cleanup --verbose
      mistdemo test-private --lookup-email me@example.com

    NOTES:
      - Requires CLOUDKIT_API_TOKEN and
        CLOUDKIT_WEB_AUTH_TOKEN
      - Use 'test-integration' for public-database tests
    """

  private let config: TestPrivateConfig

  /// Creates a new instance.
  public init(config: TestPrivateConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    let service = try MistKitClientFactory.create(for: config.base)
    // Private-database flows always carry web-auth credentials, so the same
    // service can also serve user-identity routes when this command needs
    // them. Per-call resolution picks the right token manager.
    let supportsUserContextPhases = config.base.hasUserContextCredentials

    let runner = IntegrationTestRunner(
      service: service,
      supportsUserContextPhases: supportsUserContextPhases,
      containerIdentifier: config.base.containerIdentifier,
      database: .private,
      recordCount: config.recordCount,
      assetSizeKB: config.assetSizeKB,
      skipCleanup: config.skipCleanup,
      verbose: config.verbose,
      lookupEmail: config.lookupEmail
    )

    try await runner.runPrivateWorkflow()
  }
}

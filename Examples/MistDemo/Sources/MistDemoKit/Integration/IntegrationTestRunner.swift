//
//  IntegrationTestRunner.swift
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

/// Thin façade that builds a `PhaseContext` from CLI configuration and
/// dispatches to the appropriate `PhasedIntegrationTest` implementation.
internal struct IntegrationTestRunner {
  internal let service: CloudKitService
  internal let containerIdentifier: String
  internal let database: MistKit.Database
  internal let recordCount: Int
  internal let assetSizeKB: Int
  internal let skipCleanup: Bool
  internal let verbose: Bool

  /// Run the public-database workflow.
  internal func runBasicWorkflow() async throws {
    try await PublicDatabaseTest(database: database).run(context: makeContext())
  }

  /// Run the private-database workflow.
  internal func runPrivateWorkflow() async throws {
    try await PrivateDatabaseTest().run(context: makeContext())
  }

  private func makeContext() -> PhaseContext {
    PhaseContext(
      service: service,
      containerIdentifier: containerIdentifier,
      database: database,
      recordCount: recordCount,
      assetSizeKB: assetSizeKB,
      skipCleanup: skipCleanup,
      verbose: verbose
    )
  }
}

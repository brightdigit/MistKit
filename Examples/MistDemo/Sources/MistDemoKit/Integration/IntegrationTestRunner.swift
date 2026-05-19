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

internal import Foundation
internal import MistKit

/// Thin façade that builds a `PhaseContext` from CLI configuration and
/// dispatches to the appropriate `PhasedIntegrationTest` implementation.
internal struct IntegrationTestRunner {
  internal let service: CloudKitService
  /// Whether the configured `Credentials` carry web-auth material — i.e.
  /// whether the single `service` can satisfy user-identity routes
  /// (`fetchCaller`, `lookupUsers*`, `discoverUserIdentities`). User-identity
  /// phases are scheduled only when this is true.
  internal let supportsUserContextPhases: Bool
  internal let containerIdentifier: String
  internal let database: MistKit.Database
  internal let recordCount: Int
  internal let assetSizeKB: Int
  internal let skipCleanup: Bool
  internal let verbose: Bool
  /// Optional email forwarded to `PhaseContext.lookupEmail`.
  internal let lookupEmail: String?

  /// Run the public-database workflow.
  internal func runBasicWorkflow() async throws {
    let test = PublicDatabaseTest(
      database: database,
      includeUserContextPhases: supportsUserContextPhases
    )
    try await test.run(context: makeContext())
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
      verbose: verbose,
      lookupEmail: lookupEmail
    )
  }
}

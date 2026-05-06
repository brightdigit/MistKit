//
//  DemoErrorsCommand.swift
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

/// Walks the audience through CloudKit's typed errors for the talk's
/// "CloudKit as Your Backend" / Act 3, Step 4 — Error handling segment.
public struct DemoErrorsCommand: MistDemoCommand {
  public typealias Config = DemoErrorsConfig
  public static let commandName = "demo-errors"
  public static let abstract = "Demonstrate typed CloudKit error handling (401, 404, 409)"
  public static let helpText = """
    DEMO-ERRORS - Demonstrate typed CloudKit error handling

    Triggers and prints typed CloudKitError values for the three status codes
    most commonly handled in production CloudKit apps:

      401 — Unauthorized            (invalid credentials)
      404 — Not Found               (unknown record type)
      409 — Conflict                (stale recordChangeTag, optimistic-locking failure)

    Designed for the "CloudKit as Your Backend" talk's error-handling segment.

    USAGE:
        mistdemo demo-errors [--scenario <code>] [--database <db>]

    OPTIONS:
        --scenario <code>          Which scenario to run: all (default), 401, 404, 409
        --database <type>          Database to target for 404 + 409: public, private, shared
                                   (default from MistDemoConfig: public)

    NOTES:
        • The 401 scenario constructs a *separate* service with placeholder tokens —
          your real CLOUDKIT_API_TOKEN / CLOUDKIT_WEB_AUTH_TOKEN are never modified.
        • The 409 scenario creates a real record on the target database, mutates it,
          then retries with a stale recordChangeTag to force the conflict. It cleans
          up the test record at the end (best effort).
        • Run 'mistdemo demo-errors --scenario 401' for a single quick demo.
    """

  private let config: DemoErrorsConfig

  public init(config: DemoErrorsConfig) {
    self.config = config
  }

  public func execute() async throws {
    let runner = DemoErrorsRunner(config: config.base)
    await runner.run(scenario: config.scenario)
  }
}

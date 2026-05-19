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

internal import Foundation
internal import MistKit

/// Walks the audience through CloudKit's typed errors for the talk's
/// "CloudKit as Your Backend" / Act 3, Step 4 — Error handling segment.
public struct DemoErrorsCommand: MistDemoCommand {
  /// The configuration type.
  public typealias Config = DemoErrorsConfig
  /// The command name.
  public static let commandName = "demo-errors"
  /// The command abstract.
  public static let abstract =
    "Demonstrate typed CloudKit error handling"
  /// The command help text.
  public static let helpText = """
    DEMO-ERRORS - Typed CloudKit error handling

    Triggers typed CloudKitError values for status codes
    401, 404, and 409.

    USAGE:
      mistdemo demo-errors [--scenario <code>]

    OPTIONS:
      --scenario <code>    all (default), 401, 404, 409
      --database <type>    Database for 404/409 demos

    NOTES:
      The 401 scenario uses placeholder tokens. The 409
      scenario creates, mutates, then retries with a stale
      recordChangeTag.
    """

  private let config: DemoErrorsConfig

  /// Creates a new instance.
  public init(config: DemoErrorsConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    let runner = DemoErrorsRunner(config: config.base)
    await runner.run(scenario: config.scenario)
  }
}

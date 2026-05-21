//
//  EnvironmentDiagnosticTests.swift
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
internal import Testing

/// Diagnostic suite that dumps the environment visible to the *test process*.
///
/// Simulator test processes don't inherit the runner's shell environment, so
/// CI-detection flags like `CI` / `GITHUB_ACTIONS` may not survive into the
/// process that evaluates `TestPlatform.isFlakyTimeoutSimulator`. This test
/// prints every environment variable (one per line, prefixed `ENV_DUMP:`) so
/// the CI logs reveal exactly which CI markers — if any — are actually present
/// inside iOS / watchOS / visionOS simulators. Grep the job log for `ENV_DUMP:`.
@Suite("Environment Diagnostic")
internal struct EnvironmentDiagnosticTests {
  @Test("Dump all environment variables visible to the test process")
  internal func dumpEnvironment() {
    let environment = ProcessInfo.processInfo.environment
    let names = environment.keys.sorted()

    print("ENV_DUMP: \(names.count) variables visible to the test process")
    for name in names {
      // Print only the names and the values of common CI markers — names alone
      // tell us which detection variable to key off without leaking secrets
      // (tokens/keys live in values, so we don't print arbitrary values).
      let isCIMarker = ["CI", "GITHUB_ACTIONS", "GITHUB_RUN_ID", "RUNNER_OS"]
        .contains(name)
      if isCIMarker {
        print("ENV_DUMP: \(name)=\(environment[name] ?? "")")
      } else {
        print("ENV_DUMP: \(name)")
      }
    }

    // Surface the values our gate cares about directly, even when absent.
    print("ENV_DUMP: ProcessInfo CI=\(environment["CI"] ?? "<nil>")")
    print(
      "ENV_DUMP: ProcessInfo GITHUB_ACTIONS="
        + "\(environment["GITHUB_ACTIONS"] ?? "<nil>")"
    )
  }
}

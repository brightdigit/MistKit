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
/// surfaces the relevant variables so CI logs reveal exactly which CI markers —
/// if any — are actually present inside iOS / watchOS / visionOS simulators.
///
/// `print()` from inside the simulator test process is dropped by xcodebuild's
/// console capture, so the dump is routed through Swift Testing's issue
/// reporting (which *is* captured) via `Issue.record` inside `withKnownIssue` —
/// the comment lands in the log while the recorded issue stays "known" so the
/// build stays green. Grep the job log for `ENV_DUMP:`.
@Suite("Environment Diagnostic")
internal struct EnvironmentDiagnosticTests {
  @Test("Dump CI-relevant environment variables visible to the test process")
  internal func dumpEnvironment() {
    let environment = ProcessInfo.processInfo.environment

    // CI markers we'd consider keying the flake gate off of — print their
    // values explicitly (these aren't secrets). Everything else is reported by
    // name only so we don't leak token/key values.
    let markerNames = [
      "CI", "GITHUB_ACTIONS", "GITHUB_RUN_ID", "GITHUB_WORKFLOW",
      "RUNNER_OS", "TERM", "SIMULATOR_UDID",
    ]
    let markers =
      markerNames
      .map { "\($0)=\(environment[$0] ?? "<nil>")" }
      .joined(separator: " ")
    let allNames = environment.keys.sorted().joined(separator: ",")

    withKnownIssue("ENV_DUMP diagnostic (always recorded; surfaces env in CI)") {
      Issue.record(
        Comment(
          rawValue: "ENV_DUMP: count=\(environment.count) | markers: \(markers)"
            + " | names=[\(allNames)]"
        )
      )
    }
  }
}

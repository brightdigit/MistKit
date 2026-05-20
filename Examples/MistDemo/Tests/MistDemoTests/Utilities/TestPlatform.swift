//
//  TestPlatform.swift
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

/// Compile-time platform constants exposed as runtime values so tests can read
/// them via Swift Testing traits like `.enabled(if:)` / `.disabled(if:)` —
/// keeping the gating in a trait on the test rather than `#if` around it.
internal enum TestPlatform {
  /// True when the test binary is targeting wasm32. The wasm32 CooperativeExecutor
  /// doesn't time-slice short-timeout races the same way Darwin/Linux dispatch
  /// do, and Int is 32-bit so values exceeding Int32.max trap on conversion.
  internal static let isWasm32: Bool = {
    #if arch(wasm32)
      return true
    #else
      return false
    #endif
  }()

  /// True when running inside CI on a simulator whose cooperative executor can
  /// starve the polling timeout task in `withTimeout` — see #334. The race is
  /// bounded to visionOS / watchOS simulators under CI load; local sim runs
  /// (CI env unset) stay strict to surface real regressions in the helper.
  ///
  /// The `CI` flag is delivered into the simulator's test process via the
  /// `SIMCTL_CHILD_CI` job-level env in the workflow — CoreSimulator's
  /// `launchd_sim` only inherits `SIMCTL_CHILD_`-prefixed vars present when the
  /// simulator boots, so it must be set job-wide, not just on the test step.
  internal static let isFlakyTimeoutSimulator: Bool = {
    #if (os(visionOS) || os(watchOS)) && targetEnvironment(simulator)
      return ProcessInfo.processInfo.environment["CI"] != nil
    #else
      return false
    #endif
  }()
}

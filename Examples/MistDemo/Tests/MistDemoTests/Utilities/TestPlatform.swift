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

  /// True when the current runtime's task executor cannot fairly schedule a
  /// `withTimeout`'s outer timer arm while another task is suspended. Even with
  /// the inner operation parked indefinitely, the outer `Task.sleep` still has
  /// to be woken — and on these runtimes it isn't, reliably:
  ///
  ///   - wasm32: single-threaded `CooperativeExecutor` with explicit yield
  ///     points; the timeout task's wakeup is not interleaved.
  ///   - watchOS / visionOS: cooperative scheduler under simulator CI load
  ///     delays the timeout task's wakeup past test budgets.
  ///
  /// Tests that exercise the timeout race itself must be gated on this.
  internal static let lacksPreemptiveTimerRace: Bool = {
    #if arch(wasm32) || os(watchOS) || os(visionOS)
      return true
    #else
      return false
    #endif
  }()
}

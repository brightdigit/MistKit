//
//  MistDemoLoggingBootstrap.swift
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
internal import Logging

/// Wires swift-log so MistKit's `LoggingMiddleware` actually emits the
/// HTTP request trace on `--verbose` runs.
///
/// MistKit emits at `.debug` on `com.brightdigit.MistKit.middleware`; nothing
/// is visible until `LoggingSystem.bootstrap` is called. The CLI never bootstraps
/// otherwise (the demo doesn't want generic info-level noise from every
/// subsystem), so we opt in only when the integration test commands ask for it.
internal enum MistDemoLoggingBootstrap {
  /// Bootstrap exactly once per process. `LoggingSystem.bootstrap` is
  /// itself a once-only call, so guard with an atomic flag — repeated
  /// `--verbose` invocations from the same process (e.g. tests) become
  /// no-ops instead of crashes.
  internal static func bootstrapOnce() {
    guard hasBootstrapped.exchange(true) == false else { return }
    LoggingSystem.bootstrap { label in
      var handler = StreamLogHandler.standardOutput(label: label)
      handler.logLevel =
        label == "com.brightdigit.MistKit.middleware" ? .debug : .info
      return handler
    }
  }

  private static let hasBootstrapped = AtomicBool()
}

/// Minimal atomic Bool — avoids pulling in Atomics for one flag.
private final class AtomicBool: @unchecked Sendable {
  private let lock = NSLock()
  private var value = false

  /// Set to `newValue` and return the prior value.
  func exchange(_ newValue: Bool) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    let old = value
    value = newValue
    return old
  }
}

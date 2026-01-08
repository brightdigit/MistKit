//
//  ConsoleOutput.swift
//  BushelCloud
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

/// Console output control for CLI interface
///
/// Provides user-facing console output with verbose mode support.
/// This is separate from logging, which is used for debugging and monitoring.
///
/// **Important**: All output goes to stderr to keep stdout clean for structured output (JSON, etc.)
public enum ConsoleOutput {
  /// Global verbose mode flag
  ///
  /// Note: This is marked with `nonisolated(unsafe)` because it's set once at startup
  /// before any concurrent access and then only read. This pattern is safe for CLI tools.
  nonisolated(unsafe) public static var isVerbose = false

  /// Print to stderr (keeping stdout clean for structured output)
  ///
  /// This is a drop-in replacement for Swift's `print()` that writes to stderr instead of stdout.
  /// Use this throughout the codebase to ensure JSON output on stdout remains clean.
  public static func print(_ message: String) {
    if let data = (message + "\n").data(using: .utf8) {
      FileHandle.standardError.write(data)
    }
  }

  /// Print verbose message only when verbose mode is enabled
  public static func verbose(_ message: String) {
    guard isVerbose else { return }
    ConsoleOutput.print("  \(message)")
  }

  /// Print standard informational message
  public static func info(_ message: String) {
    ConsoleOutput.print(message)
  }

  /// Print success message
  public static func success(_ message: String) {
    ConsoleOutput.print("  ✓ \(message)")
  }

  /// Print warning message
  public static func warning(_ message: String) {
    ConsoleOutput.print("  ⚠️  \(message)")
  }

  /// Print error message
  public static func error(_ message: String) {
    ConsoleOutput.print("  ❌ \(message)")
  }
}

internal import Foundation
internal import Testing

/// Platform detection utilities for testing
internal enum Platform {
  /// Returns true if the current platform supports the required crypto functionality
  /// Requires macOS 11.0+, iOS 14.0+, tvOS 14.0+, or watchOS 7.0+
  internal static let isCryptoAvailable: Bool = {
    if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
      return true
    }
    return false
  }()

  /// Returns true if running on WASM/WASI platform
  /// WASM has limited memory (~65 MB linear), large allocations (15+ MB) will fail
  internal static let isWasm: Bool = {
    #if os(WASI)
      return true
    #else
      return false
    #endif
  }()

  /// True only on Windows × Swift 6.2, which silently aborts emitting
  /// MistKitTests past a tip-over size (no `error:` / stack dump).
  /// Prefer compile-time `#if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))`
  /// for suites that must not join the emit; this flag is for gist-style traits.
  #if os(Windows) && compiler(>=6.2) && compiler(<6.3)
    internal static let isWindowsSwift62 = true
  #else
    internal static let isWindowsSwift62 = false
  #endif
}

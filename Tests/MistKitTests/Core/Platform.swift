import Foundation
import Testing

@testable import MistKit

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
}

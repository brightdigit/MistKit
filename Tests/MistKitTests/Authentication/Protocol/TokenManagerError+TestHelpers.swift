import Foundation
import Testing

@testable import MistKit

extension TokenManagerError {
  /// Test helper to process error and return localized description
  func processError() async -> String {
    localizedDescription
  }
}

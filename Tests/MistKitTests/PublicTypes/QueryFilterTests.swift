import Foundation
import Testing

@testable import MistKit

@Suite("Query Filter", .enabled(if: Platform.isCryptoAvailable))
internal enum QueryFilterTests {}

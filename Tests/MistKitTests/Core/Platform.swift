import Foundation
import Testing

extension ProcessInfo {
  /// Xcode version from environment variables
  fileprivate  var xcodeVersion: String? {
    environment["XCODE_VERSION_ACTUAL"]
  }
  
  /// Swift version from environment variables
  fileprivate  var swiftVersion: String?  {
    environment["SWIFT_VERSION"]
  }
  
  /// Xcode product build version from environment variables
  fileprivate  var xcodeProductBuildVersion: String? {
    environment["XCODE_PRODUCT_BUILD_VERSION"]
  }
  
  /// XCTest configuration file path from environment variables
  fileprivate  var xctestConfigurationFilePath: String? {
    environment["XCTestConfigurationFilePath"]
  }
  
}
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
  
  /// Returns true if running via xcodebuild by checking for Xcode-specific environment variables
  fileprivate static let isRunningViaXcodebuild: Bool = { processInfo in
    processInfo.xcodeVersion != nil ||
    processInfo.xcodeProductBuildVersion != nil ||
    processInfo.xctestConfigurationFilePath != nil
  }(ProcessInfo.processInfo)
  
  /// Returns true if running on iOS with Xcode 16.2 or older
  internal static let isiOSWithXcode16_2OrOlder: Bool = {
    // Guard: Must be running on iOS
#if !os(iOS)
    return false
#else
    // Guard: Must be using Xcode 16.2 or older (Swift 6.1 or earlier)
#if swift(>=6.2)
    return false
#else
    return isRunningViaXcodebuild
#endif
#endif
  }()
}
 
extension Comment {
  /// Generates a descriptive message for why a test is not supported
  fileprivate static func unsupportedMessage(for processInfo: ProcessInfo = .processInfo) -> Self {
    #if os(iOS)
    let platform = "iOS"
    let platformVersion = ProcessInfo.processInfo.operatingSystemVersionString
    #elseif os(macOS)
    let platform = "macOS"
    let platformVersion = ProcessInfo.processInfo.operatingSystemVersionString
    #elseif os(tvOS)
    let platform = "tvOS"
    let platformVersion = ProcessInfo.processInfo.operatingSystemVersionString
    #elseif os(watchOS)
    let platform = "watchOS"
    let platformVersion = ProcessInfo.processInfo.operatingSystemVersionString
    #elseif os(visionOS)
    let platform = "visionOS"
    let platformVersion = ProcessInfo.processInfo.operatingSystemVersionString
    #else
    let platform = "this platform"
    let platformVersion = "current version"
    #endif
    
    let versionInfo: String
    if let xcode = processInfo.xcodeVersion, let swift = processInfo.swiftVersion {
      versionInfo = "using Xcode \(xcode) and Swift \(swift)"
    } else if let xcode = processInfo.xcodeVersion {
      versionInfo = "using Xcode \(xcode)"
    } else if let swift = processInfo.swiftVersion {
      versionInfo = "using Swift \(swift)"
    } else {
      versionInfo = "with this development environment"
    }
    
    return "Test is not supported on \(platform) \(platformVersion) \(versionInfo)"
  }
  
}

/// Test trait that disables tests on iOS with Xcode 16.2 or older
/// The test is not supported on this version of Swift, Xcode and platform
extension TestTrait {
  /// Disables the test if running on iOS with Xcode 16.2 or older
  /// - Returns: A test trait that can be applied to tests
  internal static func disabledOniOSWithXcode16_2OrOlder() -> Self where Self == ConditionTrait {
    
    
    return .disabled(if: Platform.isiOSWithXcode16_2OrOlder, .unsupportedMessage())
    
  }
}

/// Suite trait that disables test suites on iOS with Xcode 16.2 or older
/// The test suite is not supported on this version of Swift, Xcode and platform
extension SuiteTrait {
  /// Disables the test suite if running on iOS with Xcode 16.2 or older
  /// - Returns: A suite trait that can be applied to test suites
  internal static func disabledOniOSWithXcode16_2OrOlder() -> Self where Self == ConditionTrait {
    
    
    return .disabled(if: Platform.isiOSWithXcode16_2OrOlder, .unsupportedMessage())
    
  }
}

import Logging

/// Centralized logging infrastructure for Celestra using swift-log
enum CelestraLogger {
  /// Logger for CloudKit operations
  static let cloudkit = Logger(label: "com.brightdigit.Celestra.cloudkit")

  /// Logger for RSS feed operations
  static let rss = Logger(label: "com.brightdigit.Celestra.rss")

  /// Logger for batch and async operations
  static let operations = Logger(label: "com.brightdigit.Celestra.operations")

  /// Logger for error handling and diagnostics
  static let errors = Logger(label: "com.brightdigit.Celestra.errors")
}

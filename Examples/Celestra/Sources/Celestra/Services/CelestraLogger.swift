import os

/// Centralized logging infrastructure for Celestra using os.Logger
enum CelestraLogger {
  /// Logger for CloudKit operations
  static let cloudkit = Logger(
    subsystem: "com.brightdigit.Celestra",
    category: "cloudkit"
  )

  /// Logger for RSS feed operations
  static let rss = Logger(
    subsystem: "com.brightdigit.Celestra",
    category: "rss"
  )

  /// Logger for batch and async operations
  static let operations = Logger(
    subsystem: "com.brightdigit.Celestra",
    category: "operations"
  )

  /// Logger for error handling and diagnostics
  static let errors = Logger(
    subsystem: "com.brightdigit.Celestra",
    category: "errors"
  )
}

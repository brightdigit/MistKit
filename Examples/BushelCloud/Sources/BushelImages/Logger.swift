import Foundation
import Logging

/// Centralized logging infrastructure for Bushel demo
///
/// This demonstrates best practices for logging in CloudKit applications:
/// - Subsystem-based organization for filtering
/// - Educational logging that teaches CloudKit concepts
/// - Verbose mode for debugging and learning
///
/// **Tutorial Note**: Use `--verbose` flag to see detailed CloudKit operations
enum BushelLogger {
    // MARK: - Subsystems

    /// Logger for CloudKit operations (sync, queries, batch uploads)
    static let cloudKit = Logger(label: "com.brightdigit.Bushel.cloudkit")

    /// Logger for external data source fetching (ipsw.me, TheAppleWiki, etc.)
    static let dataSource = Logger(label: "com.brightdigit.Bushel.datasource")

    /// Logger for sync engine orchestration
    static let sync = Logger(label: "com.brightdigit.Bushel.sync")

    // MARK: - Verbose Mode State

    /// Global verbose mode flag - set by command-line arguments
    ///
    /// Note: This is marked with `nonisolated(unsafe)` because it's set once at startup
    /// before any concurrent access and then only read. This pattern is safe for CLI tools.
    nonisolated(unsafe) static var isVerbose = false

    // MARK: - Logging Helpers

    /// Log informational message (always shown)
    static func info(_ message: String, subsystem: Logger) {
        print(message)
        subsystem.info("\(message)")
    }

    /// Log verbose message (only shown when --verbose is enabled)
    static func verbose(_ message: String, subsystem: Logger) {
        guard isVerbose else { return }
        print("  🔍 \(message)")
        subsystem.debug("\(message)")
    }

    /// Log educational explanation (shown in verbose mode)
    ///
    /// Use this to explain CloudKit concepts and MistKit usage patterns
    static func explain(_ message: String, subsystem: Logger) {
        guard isVerbose else { return }
        print("  💡 \(message)")
        subsystem.debug("EXPLANATION: \(message)")
    }

    /// Log warning message (always shown)
    static func warning(_ message: String, subsystem: Logger) {
        print("  ⚠️  \(message)")
        subsystem.warning("\(message)")
    }

    /// Log error message (always shown)
    static func error(_ message: String, subsystem: Logger) {
        print("  ❌ \(message)")
        subsystem.error("\(message)")
    }

    /// Log success message (always shown)
    static func success(_ message: String, subsystem: Logger) {
        print("  ✓ \(message)")
        subsystem.info("SUCCESS: \(message)")
    }
}

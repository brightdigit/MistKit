import Foundation
import os

/// Retry policy for transient failures with exponential backoff
struct RetryPolicy {
  /// Maximum number of attempts (including initial attempt)
  let maxAttempts: Int

  /// Base delay in seconds for first retry
  let baseDelay: TimeInterval

  /// Maximum delay in seconds (caps exponential growth)
  let maxDelay: TimeInterval

  /// Whether to add random jitter to avoid thundering herd
  let jitter: Bool

  /// Default retry policy: 3 attempts, 1s base, 30s max, with jitter
  static let `default` = RetryPolicy(
    maxAttempts: 3,
    baseDelay: 1.0,
    maxDelay: 30.0,
    jitter: true
  )

  /// Aggressive retry policy for critical operations: 5 attempts, 2s base
  static let aggressive = RetryPolicy(
    maxAttempts: 5,
    baseDelay: 2.0,
    maxDelay: 60.0,
    jitter: true
  )

  /// Conservative retry policy for rate-limited operations: 2 attempts, 5s base
  static let conservative = RetryPolicy(
    maxAttempts: 2,
    baseDelay: 5.0,
    maxDelay: 30.0,
    jitter: false
  )

  // MARK: - Execution

  /// Execute an async operation with retry logic
  /// - Parameters:
  ///   - operation: The async operation to execute
  ///   - shouldRetry: Optional custom predicate to determine if error is retriable
  ///   - logger: Optional logger for retry events
  /// - Returns: Result of the operation
  /// - Throws: Last error if all retries exhausted
  func execute<T>(
    operation: @escaping () async throws -> T,
    shouldRetry: ((Error) -> Bool)? = nil,
    logger: Logger? = nil
  ) async throws -> T {
    var lastError: Error?

    for attempt in 1...maxAttempts {
      do {
        return try await operation()
      } catch {
        lastError = error

        // Check if we should retry
        let canRetry = shouldRetry?(error)
          ?? (error as? CelestraError)?.isRetriable
          ?? true

        guard attempt < maxAttempts, canRetry else {
          break
        }

        let delay = calculateDelay(for: attempt)
        logger?.warning(
          "⚠️ Attempt \(attempt)/\(maxAttempts) failed. Retrying in \(String(format: "%.1f", delay))s... Error: \(error.localizedDescription)"
        )

        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
      }
    }

    throw lastError ?? CelestraError.networkUnavailable
  }

  // MARK: - Delay Calculation

  /// Calculate delay for a given attempt using exponential backoff
  /// - Parameter attempt: Current attempt number (1-indexed)
  /// - Returns: Delay in seconds
  private func calculateDelay(for attempt: Int) -> TimeInterval {
    // Exponential backoff: baseDelay * 2^(attempt-1)
    var delay = baseDelay * pow(2.0, Double(attempt - 1))

    // Cap at maxDelay
    delay = min(delay, maxDelay)

    // Add jitter if enabled (±20%)
    if jitter {
      let jitterRange = 0.8...1.2
      delay *= Double.random(in: jitterRange)
    }

    return delay
  }
}

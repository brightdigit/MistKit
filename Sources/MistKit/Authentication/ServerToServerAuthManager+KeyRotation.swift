//
//  ServerToServerAuthManager+KeyRotation.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import Crypto
public import Foundation

// MARK: - Key Rotation Scheduler

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension ServerToServerAuthManager {
  /// Starts the automatic key rotation scheduler based on refresh policy
  internal func startRotationScheduler() {
    guard refreshPolicy.supportsAutomaticRefresh else { return }

    let task = Task<Void, Never> { [weak self] in
      await self?.runRotationScheduler()
    }
    Task { await taskState.setTask(task) }
  }

  /// Runs the key rotation scheduler loop
  private func runRotationScheduler() async {
    while !Task.isCancelled {
      do {
        let nextRotationDate = calculateNextRotationDate()

        // Emit scheduled event
        rotationSubject.continuation.yield(
          .rotationScheduled(keyID: keyID, nextRotation: nextRotationDate))

        // Wait until the scheduled rotation time
        let now = Date()
        if nextRotationDate > now {
          let delay = nextRotationDate.timeIntervalSince(now)
          let nanoseconds = UInt64(delay * 1_000_000_000)
          try await Task.sleep(nanoseconds: nanoseconds)
        }

        // Check if we're still running after sleep
        guard !Task.isCancelled else { break }

        // Perform key rotation (this would typically involve external key management)
        await performScheduledRotation()
      } catch {
        // If sleeping was cancelled, exit gracefully
        if error is CancellationError {
          break
        }

        // For other errors, wait a bit before retrying
        try? await Task.sleep(nanoseconds: 60_000_000_000)  // 60 seconds
      }
    }
  }

  /// Calculates the next rotation date based on refresh policy
  private func calculateNextRotationDate() -> Date {
    let now = Date()

    switch refreshPolicy {
    case .periodic(let interval):
      return now.addingTimeInterval(interval)
    case .onExpiry:
      // For server-to-server keys, we don't have a specific expiry
      // Default to 24 hours for onExpiry policy
      return now.addingTimeInterval(24 * 60 * 60)
    case .manual:
      // This shouldn't be called for manual policy
      return now.addingTimeInterval(Double.greatestFiniteMagnitude)
    }
  }

  /// Performs the actual key rotation (placeholder for external key management integration)
  private func performScheduledRotation() async {
    rotationSubject.continuation.yield(.rotationStarted(keyID: keyID))

    do {
      // In a real implementation, this would:
      // 1. Generate a new key pair
      // 2. Register the new key with Apple's key management system
      // 3. Update the keyID and privateKey properties
      // 4. Store the new credentials if storage is available

      // For now, we'll just emit a completion event with the same key
      // since we can't actually perform key rotation without external integration
      rotationSubject.continuation.yield(.rotationCompleted(oldKeyID: keyID, newKeyID: keyID))

      // Store updated credentials if storage is available
      if let storage = storage {
        try await storage.store(credentials, identifier: keyID)
      }
    } catch {
      rotationSubject.continuation.yield(.rotationFailed(keyID: keyID, error: error))
    }
  }

  /// Manually triggers key rotation (can be called regardless of refresh policy)
  /// - Parameters:
  ///   - newKeyID: The new key identifier
  ///   - newPrivateKey: The new private key
  /// - Returns: New TokenCredentials with rotated key
  public func rotateKey(to newKeyID: String, privateKey newPrivateKey: P256.Signing.PrivateKey)
    async throws -> TokenCredentials
  {
    let oldKeyID = keyID

    rotationSubject.continuation.yield(.rotationStarted(keyID: oldKeyID))

    do {
      // Create new credentials with rotated key
      let newCredentials = TokenCredentials.serverToServer(
        keyID: newKeyID,
        privateKey: newPrivateKey.rawRepresentation
      )

      // Store new credentials if storage is available
      if let storage = storage {
        // Store new credentials and remove old ones
        try await storage.store(newCredentials, identifier: newKeyID)
        try await storage.remove(identifier: oldKeyID)
      }

      rotationSubject.continuation.yield(.rotationCompleted(oldKeyID: oldKeyID, newKeyID: newKeyID))

      return newCredentials
    } catch {
      rotationSubject.continuation.yield(.rotationFailed(keyID: oldKeyID, error: error))
      throw error
    }
  }

  /// Stops the automatic key rotation scheduler
  public func stopRotationScheduler() {
    Task { await taskState.cancelTask() }
  }

  /// Returns the current refresh policy
  public var currentRefreshPolicy: TokenRefreshPolicy {
    refreshPolicy
  }

  /// Returns the current retry policy
  public var currentRetryPolicy: RetryPolicy {
    retryPolicy
  }
}

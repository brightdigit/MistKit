//
//  CelestraConfig.swift
//  CelestraCloud
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

public import Foundation
public import MistKit

// MARK: - Configuration Error

/// Custom error for configuration issues (library-compatible)
public struct ConfigurationError: LocalizedError {
  /// The error message describing what went wrong.
  public let message: String

  /// A localized description of the error.
  public var errorDescription: String? {
    message
  }

  /// Creates a new configuration error.
  ///
  /// - Parameter message: The error message describing what went wrong.
  public init(_ message: String) {
    self.message = message
  }
}

// MARK: - Shared Configuration

/// Shared configuration helper for creating CloudKit service
public enum CelestraConfig {
  /// Create CloudKit service from validated configuration
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  public static func createCloudKitService(from config: ValidatedCloudKitConfiguration) throws
    -> CloudKitService
  {
    // Read private key from file
    let privateKeyPEM = try String(contentsOfFile: config.privateKeyPath, encoding: .utf8)

    // Create token manager for server-to-server authentication
    let tokenManager = try ServerToServerAuthManager(
      keyID: config.keyID,
      pemString: privateKeyPEM
    )

    // Create and return CloudKit service
    return try CloudKitService(
      containerIdentifier: config.containerID,
      tokenManager: tokenManager,
      environment: config.environment,
      database: .public
    )
  }

  /// Create CloudKit service from environment variables
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  @available(
    *, deprecated, message: "Use ConfigurationLoader with createCloudKitService(from:) instead"
  )
  public static func createCloudKitService() throws -> CloudKitService {
    // Validate required environment variables
    guard let containerID = ProcessInfo.processInfo.environment["CLOUDKIT_CONTAINER_ID"] else {
      throw ConfigurationError("CLOUDKIT_CONTAINER_ID environment variable required")
    }

    guard let keyID = ProcessInfo.processInfo.environment["CLOUDKIT_KEY_ID"] else {
      throw ConfigurationError("CLOUDKIT_KEY_ID environment variable required")
    }

    guard let privateKeyPath = ProcessInfo.processInfo.environment["CLOUDKIT_PRIVATE_KEY_PATH"]
    else {
      throw ConfigurationError("CLOUDKIT_PRIVATE_KEY_PATH environment variable required")
    }

    // Read private key from file
    let privateKeyPEM = try String(contentsOfFile: privateKeyPath, encoding: .utf8)

    // Determine environment (development or production)
    let environment: MistKit.Environment =
      ProcessInfo.processInfo.environment["CLOUDKIT_ENVIRONMENT"] == "production"
      ? .production
      : .development

    // Create token manager for server-to-server authentication
    let tokenManager = try ServerToServerAuthManager(
      keyID: keyID,
      pemString: privateKeyPEM
    )

    // Create and return CloudKit service
    return try CloudKitService(
      containerIdentifier: containerID,
      tokenManager: tokenManager,
      environment: environment,
      database: .public
    )
  }
}

//
//  CloudKitConfiguration.swift
//  BushelCloud
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
public import MistKit

// MARK: - CloudKit Configuration

/// CloudKit Server-to-Server authentication configuration
public struct CloudKitConfiguration: Sendable {
  public var containerID: String?
  public var keyID: String?
  public var privateKeyPath: String?
  public var privateKey: String?  // Raw PEM string for CI/CD
  public var environment: String?  // "development" or "production"

  public init(
    containerID: String? = nil,
    keyID: String? = nil,
    privateKeyPath: String? = nil,
    privateKey: String? = nil,
    environment: String? = nil
  ) {
    self.containerID = containerID
    self.keyID = keyID
    self.privateKeyPath = privateKeyPath
    self.privateKey = privateKey
    self.environment = environment
  }

  /// Validate that all required CloudKit fields are present
  public func validated() throws -> ValidatedCloudKitConfiguration {
    try ValidatedCloudKitConfiguration(from: self)
  }
}

/// Validated CloudKit configuration with non-optional fields
public struct ValidatedCloudKitConfiguration: Sendable {
  public let containerID: String
  public let keyID: String
  public let privateKeyPath: String  // Can be empty if privateKey is used
  public let privateKey: String?  // Optional (only one method required)
  public let environment: MistKit.Environment

  public init(from config: CloudKitConfiguration) throws {
    // Validate container ID
    guard let containerID = config.containerID, !containerID.isEmpty else {
      throw ConfigurationError(
        "CloudKit container ID required. Set CLOUDKIT_CONTAINER_ID or use --cloudkit-container-id",
        key: "cloudkit.container_id"
      )
    }

    // Validate key ID
    guard let keyID = config.keyID, !keyID.isEmpty else {
      throw ConfigurationError(
        "CloudKit key ID required. Set CLOUDKIT_KEY_ID or use --cloudkit-key-id",
        key: "cloudkit.key_id"
      )
    }

    // Validate at least ONE credential method is provided (NOT both required)
    let trimmedPrivateKey = config.privateKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let trimmedPrivateKeyPath =
      config.privateKeyPath?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    let hasPrivateKey = !trimmedPrivateKey.isEmpty
    let hasPrivateKeyPath = !trimmedPrivateKeyPath.isEmpty

    guard hasPrivateKey || hasPrivateKeyPath else {
      throw ConfigurationError(
        "Either CLOUDKIT_PRIVATE_KEY or CLOUDKIT_PRIVATE_KEY_PATH must be provided",
        key: "cloudkit.private_key"
      )
    }

    // Parse environment string to enum (case-insensitive for user convenience)
    let environmentString = (config.environment ?? "development")
      .lowercased()
      .trimmingCharacters(in: .whitespacesAndNewlines)

    guard let parsedEnvironment = MistKit.Environment(rawValue: environmentString) else {
      throw ConfigurationError(
        """
        Invalid CLOUDKIT_ENVIRONMENT: '\(config.environment ?? "")'. \
        Must be 'development' or 'production'
        """,
        key: "cloudkit.environment"
      )
    }

    self.containerID = containerID
    self.keyID = keyID
    self.privateKeyPath = hasPrivateKeyPath ? trimmedPrivateKeyPath : ""
    self.privateKey = hasPrivateKey ? trimmedPrivateKey : nil
    self.environment = parsedEnvironment
  }

  // Legacy initializer for backward compatibility (if needed by tests)
  public init(
    containerID: String,
    keyID: String,
    privateKeyPath: String,
    privateKey: String? = nil,
    environment: MistKit.Environment
  ) {
    self.containerID = containerID
    self.keyID = keyID
    self.privateKeyPath = privateKeyPath
    self.privateKey = privateKey
    self.environment = environment
  }
}

// MARK: - VirtualBuddy Configuration

/// VirtualBuddy TSS API configuration
public struct VirtualBuddyConfiguration: Sendable {
  public var apiKey: String?

  public init(apiKey: String? = nil) {
    self.apiKey = apiKey
  }
}

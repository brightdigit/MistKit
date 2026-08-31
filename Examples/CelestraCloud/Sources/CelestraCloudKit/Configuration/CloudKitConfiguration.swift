//
//  CloudKitConfiguration.swift
//  CelestraCloud
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

public import Foundation
public import MistKit

/// CloudKit credentials and environment settings
public struct CloudKitConfiguration: Sendable {
  /// Default CloudKit container identifier for Celestra
  public static let defaultContainerID = "iCloud.com.brightdigit.Celestra"

  /// CloudKit container identifier (e.g., iCloud.com.example.App)
  public var containerID: String?

  /// Server-to-Server authentication key ID from Apple Developer Console
  public var keyID: String?

  /// Absolute path to PEM-encoded private key file
  public var privateKeyPath: String?

  /// Inline PEM private key, for CI where writing a file is inconvenient
  public var privateKey: String?

  /// CloudKit environment (development or production, default: development)
  public var environment: MistKit.Environment

  /// Initialize CloudKit configuration
  /// - Parameters:
  ///   - containerID: CloudKit container identifier
  ///   - keyID: Server-to-Server authentication key ID
  ///   - privateKeyPath: Absolute path to PEM-encoded private key file
  ///   - privateKey: Inline PEM private key
  ///   - environment: CloudKit environment
  public init(
    containerID: String? = nil,
    keyID: String? = nil,
    privateKeyPath: String? = nil,
    privateKey: String? = nil,
    environment: MistKit.Environment = .development
  ) {
    self.containerID = containerID
    self.keyID = keyID
    self.privateKeyPath = privateKeyPath
    self.privateKey = privateKey
    self.environment = environment
  }

  /// Validate that all required fields are present
  public func validated() throws -> ValidatedCloudKitConfiguration {
    guard let containerID = containerID, !containerID.isEmpty else {
      throw ConfigurationError(
        "CloudKit container ID must be non-empty",
        key: "cloudkit.container-id"
      )
    }
    guard let keyID = keyID, !keyID.isEmpty else {
      throw ConfigurationError(
        "CloudKit key ID must be non-empty",
        key: "cloudkit.key-id"
      )
    }
    try KeyIDValidator.validate(keyID)

    // Exactly one credential method is required, not both.
    let trimmedPrivateKey = privateKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let trimmedPrivateKeyPath =
      privateKeyPath?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    let resolvedPrivateKey: PrivateKeyMaterial
    if !trimmedPrivateKey.isEmpty {
      try PEMValidator.validate(trimmedPrivateKey)
      resolvedPrivateKey = .raw(trimmedPrivateKey)
    } else if !trimmedPrivateKeyPath.isEmpty {
      resolvedPrivateKey = .file(path: trimmedPrivateKeyPath)
    } else {
      throw ConfigurationError(
        "Either CLOUDKIT_PRIVATE_KEY or CLOUDKIT_PRIVATE_KEY_PATH must be provided",
        key: "cloudkit.private-key"
      )
    }

    return ValidatedCloudKitConfiguration(
      containerID: containerID,
      keyID: keyID,
      privateKey: resolvedPrivateKey,
      environment: environment
    )
  }
}

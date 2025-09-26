//
//  MistKitConfiguration.swift
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

public import Foundation

/// Configuration for MistKit client
internal struct MistKitConfiguration: Sendable {
  /// The CloudKit container identifier (e.g., "iCloud.com.example.app")
  internal let container: String

  /// The CloudKit environment
  internal let environment: Environment

  /// The CloudKit database type
  internal let database: Database

  /// API Token for authentication
  internal let apiToken: String

  /// Optional Web Auth Token for user authentication
  internal let webAuthToken: String?

  /// Optional Key ID for server-to-server authentication
  internal let keyID: String?

  /// Optional private key data for server-to-server authentication
  internal let privateKeyData: Data?

  /// Optional token storage for persistence
  internal let storage: (any TokenStorage)?

  /// Protocol version (currently "1")
  internal let version: String = "1"

  /// Computed server URL based on configuration
  internal var serverURL: URL {
    guard let url = URL(string: "https://api.apple-cloudkit.com") else {
      fatalError("Invalid CloudKit API URL")
    }
    return url
  }

  /// Initialize MistKit configuration
  internal init(
    container: String,
    environment: Environment,
    database: Database = .private,
    apiToken: String,
    webAuthToken: String? = nil,
    keyID: String? = nil,
    privateKeyData: Data? = nil,
    storage: (any TokenStorage)? = nil
  ) {
    precondition(!container.isEmpty, "Container identifier cannot be empty")
    // Allow empty API token only if we have server-to-server authentication parameters
    if apiToken.isEmpty {
      precondition(
        keyID != nil && privateKeyData != nil,
        "API token cannot be empty unless using server-to-server authentication "
          + "(keyID and privateKeyData must be provided)"
      )
    }

    self.container = container
    self.environment = environment
    self.database = database
    self.apiToken = apiToken
    self.webAuthToken = webAuthToken
    self.keyID = keyID
    self.privateKeyData = privateKeyData
    self.storage = storage
  }

  /// Creates an appropriate TokenManager based on the configuration
  /// - Returns: A TokenManager instance matching the authentication method
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal func createTokenManager() -> any TokenManager {
    // Default creation logic
    if let keyID = keyID, let privateKeyData = privateKeyData {
      do {
        return try ServerToServerAuthManager(
          keyID: keyID,
          privateKeyData: privateKeyData,
          storage: storage
        )
      } catch {
        fatalError("Failed to create ServerToServerAuthManager: \(error)")
      }
    } else if let webAuthToken = webAuthToken {
      return WebAuthTokenManager(
        apiToken: apiToken,
        webAuthToken: webAuthToken
      )
    } else {
      return APITokenManager(apiToken: apiToken)
    }
  }
}

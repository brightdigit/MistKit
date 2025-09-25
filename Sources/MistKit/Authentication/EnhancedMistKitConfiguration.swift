//
//  EnhancedMistKitConfiguration.swift
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

/// Enhanced configuration with dependency injection support
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public struct EnhancedMistKitConfiguration: Sendable {
  public let container: String
  public let environment: Environment
  public let database: Database
  public let apiToken: String
  public let webAuthToken: String?
  public let keyID: String?
  public let privateKeyData: Data?
  public let storage: (any TokenStorage)?
  public let refreshManager: (any TokenRefreshManager)?
  public let dependencyContainer: (any DependencyContainer)?

  public init(
    container: String,
    environment: Environment,
    database: Database = .private,
    apiToken: String,
    webAuthToken: String? = nil,
    keyID: String? = nil,
    privateKeyData: Data? = nil,
    storage: (any TokenStorage)? = nil,
    refreshManager: (any TokenRefreshManager)? = nil,
    dependencyContainer: (any DependencyContainer)? = nil
  ) {
    self.container = container
    self.environment = environment
    self.database = database
    self.apiToken = apiToken
    self.webAuthToken = webAuthToken
    self.keyID = keyID
    self.privateKeyData = privateKeyData
    self.storage = storage
    self.refreshManager = refreshManager
    self.dependencyContainer = dependencyContainer
  }

  /// Creates a token manager using dependency injection
  /// - Returns: TokenManager instance
  /// - Throws: TokenManagerError if creation fails
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  public func createTokenManager() async throws -> any TokenManager {
    // Try dependency container first
    if let container = dependencyContainer {
      do {
        let factory: any TokenManagerFactory = try container.resolve(TokenManagerFactory.self)
        return try await factory.createTokenManager(
          configuration: toMistKitConfiguration(),
          storage: storage
        )
      } catch {
        // Fall back to default creation
      }
    }

    // Default creation logic
    if let keyID = keyID, let privateKeyData = privateKeyData {
      return try ServerToServerAuthManager(
        keyID: keyID,
        privateKeyData: privateKeyData,
        storage: storage
      )
    } else if let webAuthToken = webAuthToken {
      return WebAuthTokenManager(
        apiToken: apiToken,
        webAuthToken: webAuthToken,
        storage: storage
      )
    } else {
      return APITokenManager(apiToken: apiToken)
    }
  }

  /// Converts to legacy MistKitConfiguration
  private func toMistKitConfiguration() -> MistKitConfiguration {
    MistKitConfiguration(
      container: container,
      environment: environment,
      database: database,
      apiToken: apiToken,
      webAuthToken: webAuthToken,
      keyID: keyID,
      privateKeyData: privateKeyData,
      storage: storage,
      dependencyContainer: dependencyContainer
    )
  }
}

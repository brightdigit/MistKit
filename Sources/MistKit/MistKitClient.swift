//
//  MistKitClient.swift
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
import HTTPTypes
import OpenAPIRuntime
import OpenAPIURLSession

#if canImport(Crypto)
  import Crypto
#endif

/// A client for interacting with CloudKit Web Services
public struct MistKitClient {
  /// The underlying OpenAPI client
  internal let client: Client

  /// The CloudKit container configuration
  public let configuration: MistKitConfiguration

  /// Initialize a new MistKit client
  /// - Parameter configuration: The CloudKit configuration including container,
  ///   environment, and authentication
  /// - Throws: ClientError if initialization fails
  public init(configuration: MistKitConfiguration) throws {
    self.configuration = configuration

    // Create appropriate TokenManager from configuration
    let tokenManager = configuration.createTokenManager()

    // Create the OpenAPI client with custom server URL and middleware
    self.client = Client(
      serverURL: configuration.serverURL,
      transport: URLSessionTransport(),
      middlewares: [
        AuthenticationMiddleware(tokenManager: tokenManager),
        LoggingMiddleware(),
      ]
    )
  }

  /// Initialize a new MistKit client with a custom TokenManager
  /// - Parameters:
  ///   - configuration: The CloudKit configuration
  ///   - tokenManager: Custom token manager for authentication
  /// - Throws: ClientError if initialization fails
  public init(configuration: MistKitConfiguration, tokenManager: any TokenManager) throws {
    self.configuration = configuration

    // Validate server-to-server authentication restrictions
    try Self.validateServerToServerConfiguration(
      configuration: configuration, tokenManager: tokenManager
    )

    // Create the OpenAPI client with custom server URL and middleware
    self.client = Client(
      serverURL: configuration.serverURL,
      transport: URLSessionTransport(),
      middlewares: [
        AuthenticationMiddleware(tokenManager: tokenManager),
        LoggingMiddleware(),
      ]
    )
  }

  /// Initialize a new MistKit client with a custom TokenManager and individual parameters
  /// - Parameters:
  ///   - container: CloudKit container identifier
  ///   - environment: CloudKit environment (development/production)
  ///   - database: CloudKit database (public/private/shared)
  ///   - tokenManager: Custom token manager for authentication
  /// - Throws: ClientError if initialization fails
  public init(
    container: String,
    environment: Environment,
    database: Database,
    tokenManager: any TokenManager
  ) throws {
    let configuration = MistKitConfiguration(
      container: container,
      environment: environment,
      database: database,
      apiToken: ""  // Not used with custom TokenManager
    )

    try self.init(configuration: configuration, tokenManager: tokenManager)
  }

  // MARK: - Server-to-Server Validation

  /// Validates that server-to-server authentication is only used with the public database
  /// - Parameters:
  ///   - configuration: The CloudKit configuration
  ///   - tokenManager: The token manager being used
  /// - Throws: TokenManagerError if server-to-server auth is used with non-public database
  private static func validateServerToServerConfiguration(
    configuration: MistKitConfiguration,
    tokenManager: any TokenManager
  ) throws {
    // Check if this is a server-to-server token manager (only available on newer platforms)
    #if canImport(Crypto)
      if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
        if tokenManager is ServerToServerAuthManager {
          // Server-to-server authentication only supports the public database
          guard configuration.database == .public else {
            throw TokenManagerError.invalidCredentials(
              reason: """
                Server-to-server authentication only supports the public database. Current database: \(configuration.database). \
                Use MistKitConfiguration.serverToServer() for proper configuration.
                """
            )
          }
        }
      }
    #endif
  }
}

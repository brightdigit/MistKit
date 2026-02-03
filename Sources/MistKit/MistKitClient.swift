//
//  MistKitClient.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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

import Crypto
#if os(Linux)
@preconcurrency import Foundation
import FoundationNetworking
#else
import Foundation
#endif
import HTTPTypes
import OpenAPIRuntime

#if !os(WASI)
  import OpenAPIURLSession
#endif

/// A client for interacting with CloudKit Web Services
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
internal struct MistKitClient {
  /// The underlying OpenAPI client
  internal let client: Client
  /// The asset uploader for CloudKit CDN uploads
  internal let assetUploader: any AssetUploader

  /// Initialize a new MistKit client
  /// - Parameters:
  ///   - configuration: The CloudKit configuration including container,
  ///     environment, and authentication
  ///   - transport: Custom transport for network requests
  ///   - assetUploader: Optional custom asset uploader
  /// - Throws: ClientError if initialization fails
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal init(
    configuration: MistKitConfiguration,
    transport: any ClientTransport,
    assetUploader: (any AssetUploader)? = nil
  ) throws {
    // Create appropriate TokenManager from configuration
    let tokenManager = try configuration.createTokenManager()

    #if !os(WASI)
      // Create dedicated URLSession for CDN uploads
      // Using a separate URLSession ensures separate HTTP/2 connection pools
      // to avoid 421 "Misdirected Request" errors between API and CDN hosts
      let cdnSession = URLSession(configuration: .default)
      self.assetUploader = assetUploader ?? DefaultAssetUploader(urlSession: cdnSession)
    #else
      self.assetUploader = assetUploader ?? WASIAssetUploader()
    #endif

    // Create the OpenAPI client with custom server URL and middleware
    self.client = Client(
      serverURL: configuration.serverURL,
      transport: transport,
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
  ///   - transport: Custom transport for network requests
  ///   - assetUploader: Optional custom asset uploader
  /// - Throws: ClientError if initialization fails
  internal init(
    configuration: MistKitConfiguration,
    tokenManager: any TokenManager,
    transport: any ClientTransport,
    assetUploader: (any AssetUploader)? = nil
  ) throws {
    // Validate server-to-server authentication restrictions
    try Self.validateServerToServerConfiguration(
      configuration: configuration,
      tokenManager: tokenManager
    )

    #if !os(WASI)
      // Create dedicated URLSession for CDN uploads
      // Using a separate URLSession ensures separate HTTP/2 connection pools
      // to avoid 421 "Misdirected Request" errors between API and CDN hosts
      let cdnSession = URLSession(configuration: .default)
      self.assetUploader = assetUploader ?? DefaultAssetUploader(urlSession: cdnSession)
    #else
      self.assetUploader = assetUploader ?? WASIAssetUploader()
    #endif

    // Create the OpenAPI client with custom server URL and middleware
    self.client = Client(
      serverURL: configuration.serverURL,
      transport: transport,
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
  ///   - transport: Custom transport for network requests
  ///   - assetUploader: Optional custom asset uploader
  /// - Throws: ClientError if initialization fails
  internal init(
    container: String,
    environment: Environment,
    database: Database,
    tokenManager: any TokenManager,
    transport: any ClientTransport,
    assetUploader: (any AssetUploader)? = nil
  ) throws {
    // Check if this is a server-to-server token manager
    var keyID: String?
    var privateKeyData: Data?
    var apiToken: String = ""

    if let serverManager = tokenManager as? ServerToServerAuthManager {
      // Extract keyID and privateKeyData from ServerToServerAuthManager
      keyID = serverManager.keyIdentifier
      privateKeyData = serverManager.privateKeyData
    } else if let apiManager = tokenManager as? APITokenManager {
      // Extract API token from APITokenManager
      apiToken = apiManager.token
    }

    let configuration = MistKitConfiguration(
      container: container,
      environment: environment,
      database: database,
      apiToken: apiToken,  // Use extracted API token if available
      keyID: keyID,
      privateKeyData: privateKeyData
    )

    try self.init(
      configuration: configuration,
      tokenManager: tokenManager,
      transport: transport,
      assetUploader: assetUploader
    )
  }

  // MARK: - Convenience Initializers

  #if !os(WASI)
    /// Initialize a new MistKit client with default URLSessionTransport
    /// - Parameters:
    ///   - configuration: The CloudKit configuration including container,
    ///     environment, and authentication
    ///   - assetUploader: Optional custom asset uploader
    /// - Throws: ClientError if initialization fails
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    internal init(
      configuration: MistKitConfiguration,
      assetUploader: (any AssetUploader)? = nil
    ) throws {
      try self.init(
        configuration: configuration,
        transport: URLSessionTransport(),
        assetUploader: assetUploader
      )
    }

    /// Initialize a new MistKit client with a custom TokenManager and individual parameters
    /// using default URLSessionTransport
    /// - Parameters:
    ///   - container: CloudKit container identifier
    ///   - environment: CloudKit environment (development/production)
    ///   - database: CloudKit database (public/private/shared)
    ///   - tokenManager: Custom token manager for authentication
    ///   - assetUploader: Optional custom asset uploader
    /// - Throws: ClientError if initialization fails
    internal init(
      container: String,
      environment: Environment,
      database: Database,
      tokenManager: any TokenManager,
      assetUploader: (any AssetUploader)? = nil
    ) throws {
      try self.init(
        container: container,
        environment: environment,
        database: database,
        tokenManager: tokenManager,
        transport: URLSessionTransport(),
        assetUploader: assetUploader
      )
    }
  #endif

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
    // Check if this is a server-to-server token manager
    if tokenManager is ServerToServerAuthManager {
      // Server-to-server authentication only supports the public database
      guard configuration.database == .public else {
        throw TokenManagerError.invalidCredentials(
          .serverToServerOnlySupportsPublicDatabase(configuration.database.rawValue)
        )
      }
    }
  }
}

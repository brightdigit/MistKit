//
//  CloudKitService+Initialization.swift
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

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
public import OpenAPIRuntime

// MARK: - Generic Initializers (All Platforms)

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
  /// Initialize CloudKit service with web authentication
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  public init(
    containerIdentifier: String,
    apiToken: String,
    webAuthToken: String,
    transport: any ClientTransport
  ) throws {
    self.containerIdentifier = containerIdentifier
    self.apiToken = apiToken
    self.environment = .development
    self.database = .private

    let config = MistKitConfiguration(
      container: containerIdentifier,
      environment: .development,
      database: .private,
      apiToken: apiToken,
      webAuthToken: webAuthToken
    )
    self.mistKitClient = try MistKitClient(
      configuration: config,
      transport: transport
    )
  }

  /// Initialize CloudKit service with API-only authentication
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  public init(
    containerIdentifier: String,
    apiToken: String,
    transport: any ClientTransport
  ) throws {
    self.containerIdentifier = containerIdentifier
    self.apiToken = apiToken
    self.environment = .development
    self.database = .public  // API-only supports public database

    let config = MistKitConfiguration(
      container: containerIdentifier,
      environment: .development,
      database: .public,  // API-only supports public database
      apiToken: apiToken,
      webAuthToken: nil,
      keyID: nil,
      privateKeyData: nil
    )
    self.mistKitClient = try MistKitClient(
      configuration: config,
      transport: transport
    )
  }

  /// Initialize CloudKit service with a custom TokenManager
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  public init(
    containerIdentifier: String,
    tokenManager: any TokenManager,
    environment: Environment = .development,
    database: Database = .private,
    transport: any ClientTransport
  ) throws {
    self.containerIdentifier = containerIdentifier
    self.apiToken = ""  // Not used when providing TokenManager directly
    self.environment = environment
    self.database = database

    self.mistKitClient = try MistKitClient(
      container: containerIdentifier,
      environment: environment,
      database: database,
      tokenManager: tokenManager,
      transport: transport
    )
  }
}

// MARK: - URLSession Convenience Initializers (Non-WASI Platforms)

#if !os(WASI)
  import OpenAPIURLSession

  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  extension CloudKitService {
    /// Initialize CloudKit service with web authentication using default URLSessionTransport
    ///
    /// This convenience initializer is only available on platforms that support URLSession.
    /// For WASI builds, use the generic initializer that accepts a transport parameter.
    public init(
      containerIdentifier: String,
      apiToken: String,
      webAuthToken: String
    ) throws {
      try self.init(
        containerIdentifier: containerIdentifier,
        apiToken: apiToken,
        webAuthToken: webAuthToken,
        transport: URLSessionTransport()
      )
    }

    /// Initialize CloudKit service with API-only authentication using default URLSessionTransport
    ///
    /// This convenience initializer is only available on platforms that support URLSession.
    /// For WASI builds, use the generic initializer that accepts a transport parameter.
    public init(
      containerIdentifier: String,
      apiToken: String
    ) throws {
      try self.init(
        containerIdentifier: containerIdentifier,
        apiToken: apiToken,
        transport: URLSessionTransport()
      )
    }

    /// Initialize CloudKit service with a custom TokenManager using default URLSessionTransport
    ///
    /// This convenience initializer is only available on platforms that support URLSession.
    /// For WASI builds, use the generic initializer that accepts a transport parameter.
    public init(
      containerIdentifier: String,
      tokenManager: any TokenManager,
      environment: Environment = .development,
      database: Database = .private
    ) throws {
      try self.init(
        containerIdentifier: containerIdentifier,
        tokenManager: tokenManager,
        environment: environment,
        database: database,
        transport: URLSessionTransport()
      )
    }
  }
#endif

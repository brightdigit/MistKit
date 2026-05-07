//
//  MistDemoConfig.swift
//  MistDemo
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

public import ConfigKeyKit
import Configuration
import Foundation
public import MistKit

/// Centralized configuration for MistDemo.
public struct MistDemoConfig: Sendable, ConfigurationParseable {
  /// The configuration reader type.
  public typealias ConfigReader = MistDemoConfiguration
  /// The base configuration type.
  public typealias BaseConfig = Never

  // MARK: - CloudKit Core Configuration

  /// CloudKit container identifier.
  internal let containerIdentifier: String
  /// CloudKit API token (secret).
  internal let apiToken: String
  /// CloudKit environment (development or production).
  internal let environment: MistKit.Environment
  /// CloudKit database (public, private, or shared).
  internal let database: MistKit.Database

  // MARK: - Authentication Configuration

  /// Web authentication token (secret).
  internal let webAuthToken: String?
  /// Server-to-server key ID.
  internal let keyID: String?
  /// Server-to-server private key (secret).
  internal let privateKey: String?
  /// Path to server-to-server private key file.
  internal let privateKeyFile: String?

  // MARK: - Server Configuration

  /// Server host for authentication.
  internal let host: String
  /// Server port for authentication.
  internal let port: Int
  /// Authentication timeout in seconds.
  internal let authTimeout: Double

  // MARK: - Test Flags

  /// Skip authentication and use provided token directly.
  internal let skipAuth: Bool
  /// Test all authentication methods.
  internal let testAllAuth: Bool
  /// Test API-only authentication.
  internal let testApiOnly: Bool
  /// Test AdaptiveTokenManager transitions.
  internal let testAdaptive: Bool
  /// Test server-to-server authentication.
  internal let testServerToServer: Bool

  // MARK: - Demo Flags

  /// Use deliberately invalid credentials (for the talk's 401 demo).
  internal let badCredentials: Bool

  // MARK: - Initialization

  /// Initialize with Swift Configuration's hierarchical providers.
  public init(
    configuration: MistDemoConfiguration,
    base: Never? = nil
  ) async throws {
    let config = configuration
    let core = Self.parseCoreConfig(config)
    self.containerIdentifier = core.containerIdentifier
    self.apiToken = core.apiToken
    self.environment = core.environment

    let databaseString =
      config.string(forKey: "database", default: "public") ?? "public"
    guard let database = MistKit.Database(rawValue: databaseString) else {
      throw ConfigurationError.invalidDatabase(databaseString)
    }
    self.database = database

    let auth = Self.parseAuthConfig(config)
    self.webAuthToken = auth.webAuthToken
    self.keyID = auth.keyID
    self.privateKey = auth.privateKey
    self.privateKeyFile = auth.privateKeyFile

    let server = Self.parseServerConfig(config)
    self.host = server.host
    self.port = server.port
    self.authTimeout = server.authTimeout

    let flags = Self.parseFlags(config)
    self.skipAuth = flags.skipAuth
    self.testAllAuth = flags.testAllAuth
    self.testApiOnly = flags.testApiOnly
    self.testAdaptive = flags.testAdaptive
    self.testServerToServer = flags.testServerToServer
    self.badCredentials = flags.badCredentials
  }

  /// Memberwise initializer used internally for overrides.
  internal init(
    containerIdentifier: String,
    apiToken: String,
    environment: MistKit.Environment,
    database: MistKit.Database,
    webAuthToken: String?,
    keyID: String?,
    privateKey: String?,
    privateKeyFile: String?,
    host: String,
    port: Int,
    authTimeout: Double,
    skipAuth: Bool,
    testAllAuth: Bool,
    testApiOnly: Bool,
    testAdaptive: Bool,
    testServerToServer: Bool,
    badCredentials: Bool
  ) {
    self.containerIdentifier = containerIdentifier
    self.apiToken = apiToken
    self.environment = environment
    self.database = database
    self.webAuthToken = webAuthToken
    self.keyID = keyID
    self.privateKey = privateKey
    self.privateKeyFile = privateKeyFile
    self.host = host
    self.port = port
    self.authTimeout = authTimeout
    self.skipAuth = skipAuth
    self.testAllAuth = testAllAuth
    self.testApiOnly = testApiOnly
    self.testAdaptive = testAdaptive
    self.testServerToServer = testServerToServer
    self.badCredentials = badCredentials
  }

  /// Returns a copy with the given database override.
  internal func with(
    database: MistKit.Database
  ) -> MistDemoConfig {
    MistDemoConfig(
      containerIdentifier: containerIdentifier,
      apiToken: apiToken,
      environment: environment,
      database: database,
      webAuthToken: webAuthToken,
      keyID: keyID,
      privateKey: privateKey,
      privateKeyFile: privateKeyFile,
      host: host,
      port: port,
      authTimeout: authTimeout,
      skipAuth: skipAuth,
      testAllAuth: testAllAuth,
      testApiOnly: testApiOnly,
      testAdaptive: testAdaptive,
      testServerToServer: testServerToServer,
      badCredentials: badCredentials
    )
  }
}

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

/// Centralized configuration for MistDemo
/// Implements hierarchical configuration using Swift Configuration (CLI → ENV → defaults)
public struct MistDemoConfig: Sendable, ConfigurationParseable {
  public typealias ConfigReader = MistDemoConfiguration
  public typealias BaseConfig = Never
  // MARK: - CloudKit Core Configuration

  /// CloudKit container identifier
  let containerIdentifier: String

  /// CloudKit API token (secret)
  let apiToken: String

  /// CloudKit environment (development or production)
  let environment: MistKit.Environment

  /// CloudKit database (public, private, or shared)
  let database: MistKit.Database

  // MARK: - Authentication Configuration

  /// Web authentication token (secret)
  let webAuthToken: String?

  /// Server-to-server key ID
  let keyID: String?

  /// Server-to-server private key (secret)
  let privateKey: String?

  /// Path to server-to-server private key file
  let privateKeyFile: String?

  // MARK: - Server Configuration

  /// Server host for authentication
  let host: String

  /// Server port for authentication
  let port: Int

  /// Authentication timeout in seconds (default: 300 = 5 minutes)
  let authTimeout: Double

  // MARK: - Test Flags

  /// Skip authentication and use provided token directly
  /// @deprecated: Automatic detection based on web-auth-token presence. This flag is ignored.
  let skipAuth: Bool

  /// Test all authentication methods
  let testAllAuth: Bool

  /// Test API-only authentication
  let testApiOnly: Bool

  /// Test AdaptiveTokenManager transitions
  let testAdaptive: Bool

  /// Test server-to-server authentication
  let testServerToServer: Bool

  // MARK: - Demo Flags

  /// Use deliberately invalid credentials (for the talk's 401 demo).
  /// When true, the configured tokens are swapped with placeholders before the
  /// service is constructed, producing a typed 401 from CloudKit on the next call.
  let badCredentials: Bool

  // MARK: - Initialization

  /// Initialize with Swift Configuration's hierarchical provider setup
  public init(configuration: MistDemoConfiguration, base: Never? = nil) async throws {
    let config = configuration

    // CloudKit Core
    self.containerIdentifier =
      config.string(
        forKey: "container.identifier",
        default: MistDemoConstants.Defaults.containerIdentifier
      ) ?? MistDemoConstants.Defaults.containerIdentifier

    self.apiToken =
      config.string(
        forKey: "api.token",
        default: "",
        isSecret: true
      ) ?? ""

    let envString =
      config.string(
        forKey: "environment",
        default: "development"
      ) ?? "development"
    self.environment = envString == "production" ? .production : .development

    let databaseString = config.string(forKey: "database", default: "public") ?? "public"
    guard let database = MistKit.Database(rawValue: databaseString) else {
      throw ConfigurationError.invalidDatabase(databaseString)
    }
    self.database = database

    // Authentication
    self.webAuthToken = config.string(
      forKey: "web.auth.token",
      isSecret: true
    )

    self.keyID = config.string(
      forKey: "key.id"
    )

    self.privateKey = config.string(
      forKey: "private.key",
      isSecret: true
    )

    self.privateKeyFile = config.string(
      forKey: "private.key.path"
    )

    // Server
    self.host =
      config.string(
        forKey: "host",
        default: "127.0.0.1"
      ) ?? "127.0.0.1"

    self.port =
      config.int(
        forKey: "port",
        default: 8_080
      ) ?? 8_080

    self.authTimeout = Double(
      config.int(
        forKey: "auth.timeout",
        default: 300
      ) ?? 300)

    // Test flags
    self.skipAuth = config.bool(
      forKey: "skip.auth",
      default: false
    )

    self.testAllAuth = config.bool(
      forKey: "test.all.auth",
      default: false
    )

    self.testApiOnly = config.bool(
      forKey: "test.api.only",
      default: false
    )

    self.testAdaptive = config.bool(
      forKey: "test.adaptive",
      default: false
    )

    self.testServerToServer = config.bool(
      forKey: "test.server.to.server",
      default: false
    )

    // Demo flags
    self.badCredentials = config.bool(
      forKey: "bad.credentials",
      default: false
    )
  }

  /// Memberwise initializer used internally to copy a config with overrides
  /// (e.g. `with(database:)`). Not part of the public surface.
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

  /// Returns a copy of this config with the given database, leaving all other
  /// fields unchanged. Used by commands whose identity pins a database
  /// (e.g. `test-private` always targets `.private`).
  internal func with(database: MistKit.Database) -> MistDemoConfig {
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

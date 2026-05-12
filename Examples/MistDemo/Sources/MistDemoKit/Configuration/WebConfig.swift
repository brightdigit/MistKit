//
//  WebConfig.swift
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
import Foundation
public import MistKit

/// Configuration for the long-running `web` demo command.
///
/// Pairs the same auth-flow inputs as `AuthTokenConfig` with the CloudKit
/// environment so the server can build a `CloudKitService` after the user
/// completes the browser-side auth round trip. If server-to-server key
/// material is also supplied (`keyID` + either `privateKey` or
/// `privateKeyFile`), the demo additionally enables the public database
/// path so the UI can compare web-auth vs S2S signing side-by-side.
public struct WebConfig: Sendable, ConfigurationParseable {
  /// The configuration reader type.
  public typealias ConfigReader = MistDemoConfiguration
  /// The base configuration type.
  public typealias BaseConfig = Never

  /// The CloudKit API token.
  public let apiToken: String
  /// The CloudKit container identifier.
  public let containerIdentifier: String
  /// The CloudKit environment (development / production).
  public let environment: MistKit.Environment
  /// The server port.
  public let port: Int
  /// The server host.
  public let host: String
  /// Whether to open the browser to the demo URL on startup.
  /// Defaults to `false` for `web` — the long-running server is often
  /// driven from another machine (or a non-default browser), so silent
  /// startup is the safer UX. Override with `--browser`.
  public let openBrowser: Bool
  /// Server-to-server key identifier (optional). When paired with
  /// `privateKey` or `privateKeyFile`, unlocks the public-database path.
  public let keyID: String?
  /// Server-to-server private key material (optional, secret).
  public let privateKey: String?
  /// Path to a server-to-server private key file (optional).
  public let privateKeyFile: String?

  /// Whether the configuration carries the credentials needed to target
  /// the public database via server-to-server signing.
  public var publicDatabaseAvailable: Bool {
    guard let keyID, !keyID.isEmpty else {
      return false
    }
    let hasInlineKey = (privateKey?.isEmpty == false)
    let hasKeyFile = (privateKeyFile?.isEmpty == false)
    return hasInlineKey || hasKeyFile
  }

  /// Creates a new instance.
  public init(
    apiToken: String,
    containerIdentifier: String = MistDemoConstants.Defaults.containerIdentifier,
    environment: MistKit.Environment = .development,
    port: Int = 8_080,
    host: String = "127.0.0.1",
    openBrowser: Bool = false,
    keyID: String? = nil,
    privateKey: String? = nil,
    privateKeyFile: String? = nil
  ) {
    self.apiToken = apiToken
    self.containerIdentifier = containerIdentifier
    self.environment = environment
    self.port = port
    self.host = host
    self.openBrowser = openBrowser
    self.keyID = keyID
    self.privateKey = privateKey
    self.privateKeyFile = privateKeyFile
  }

  /// Parse configuration from command line arguments.
  public init(
    configuration: MistDemoConfiguration,
    base: Never? = nil
  ) async throws {
    let configReader = configuration

    let apiToken =
      configReader.string(forKey: "api.token", isSecret: true) ?? ""
    guard !apiToken.isEmpty else {
      throw ConfigurationError.missingRequired(
        "api.token",
        suggestion:
          "Provide via --api-token or CLOUDKIT_API_TOKEN environment variable"
      )
    }

    let containerIdentifier =
      configReader.string(
        forKey: "container.identifier",
        default: MistDemoConstants.Defaults.containerIdentifier
      ) ?? MistDemoConstants.Defaults.containerIdentifier

    let envString =
      configReader.string(forKey: "environment", default: "development")
      ?? "development"
    guard let environment = MistKit.Environment(caseInsensitive: envString) else {
      throw ConfigurationError.invalidEnvironment(envString)
    }

    let port =
      configReader.int(forKey: "port", default: 8_080) ?? 8_080
    let host =
      configReader.string(forKey: "host", default: "127.0.0.1")
      ?? "127.0.0.1"
    let openBrowser = BrowserFlagResolver.resolve(
      configReader: configReader,
      default: false
    )

    let keyID = configReader.string(forKey: "key.id")
    let privateKey = configReader.string(
      forKey: "private.key",
      isSecret: true
    )
    let privateKeyFile = configReader.string(forKey: "private.key.path")

    self.init(
      apiToken: apiToken,
      containerIdentifier: containerIdentifier,
      environment: environment,
      port: port,
      host: host,
      openBrowser: openBrowser,
      keyID: keyID,
      privateKey: privateKey,
      privateKeyFile: privateKeyFile
    )
  }
}

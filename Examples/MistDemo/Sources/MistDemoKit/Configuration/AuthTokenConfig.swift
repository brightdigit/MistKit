//
//  AuthTokenConfig.swift
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
internal import Foundation
public import MistKit

/// Configuration for auth-token command.
public struct AuthTokenConfig: Sendable, ConfigurationParseable {
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
  /// The server port for authentication.
  public let port: Int
  /// The server host for authentication.
  public let host: String
  /// Whether to open the browser to the demo URL on startup.
  /// Defaults to `true` for `auth-token` — the captured token is the
  /// command's whole reason for existing, so a hands-off flow is the
  /// expected UX.
  public let openBrowser: Bool

  /// Creates a new instance.
  public init(
    apiToken: String,
    // Demo default — override via --container-identifier or config key "container.identifier"
    containerIdentifier: String = MistDemoConstants.Defaults.containerIdentifier,
    environment: MistKit.Environment = .development,
    port: Int = 8_080,
    host: String = "127.0.0.1",
    openBrowser: Bool = true
  ) {
    self.apiToken = apiToken
    self.containerIdentifier = containerIdentifier
    self.environment = environment
    self.port = port
    self.host = host
    self.openBrowser = openBrowser
  }

  /// Parse configuration from command line arguments.
  public init(
    configuration: MistDemoConfiguration,
    base: Never? = nil
  ) async throws {
    let configReader = configuration

    // Parse command-specific options
    let apiToken =
      configReader.string(forKey: "api.token", isSecret: true) ?? ""
    guard !apiToken.isEmpty else {
      throw ConfigurationError.missingRequired(
        "api.token",
        suggestion:
          "Provide via --api-token or CLOUDKIT_API_TOKEN environment variable"
      )
    }

    // Demo default — override via --container-identifier
    // or config key "container.identifier"
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
      default: true
    )

    self.init(
      apiToken: apiToken,
      containerIdentifier: containerIdentifier,
      environment: environment,
      port: port,
      host: host,
      openBrowser: openBrowser
    )
  }
}

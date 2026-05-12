//
//  WebDemoConfig.swift
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
/// completes the browser-side auth round trip.
public struct WebDemoConfig: Sendable, ConfigurationParseable {
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
  /// Whether to skip opening the browser.
  public let noBrowser: Bool

  /// Creates a new instance.
  public init(
    apiToken: String,
    containerIdentifier: String = MistDemoConstants.Defaults.containerIdentifier,
    environment: MistKit.Environment = .development,
    port: Int = 8_080,
    host: String = "127.0.0.1",
    noBrowser: Bool = false
  ) {
    self.apiToken = apiToken
    self.containerIdentifier = containerIdentifier
    self.environment = environment
    self.port = port
    self.host = host
    self.noBrowser = noBrowser
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
    let noBrowser =
      configReader.bool(forKey: "no.browser", default: false)

    self.init(
      apiToken: apiToken,
      containerIdentifier: containerIdentifier,
      environment: environment,
      port: port,
      host: host,
      noBrowser: noBrowser
    )
  }
}

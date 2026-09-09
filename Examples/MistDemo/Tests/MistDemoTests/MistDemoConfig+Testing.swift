//
//  MistDemoConfig+Testing.swift
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

internal import ConfigKeyKit
internal import MistKitConfiguration
internal import Configuration
internal import Foundation
internal import MistKit

@testable import MistDemoKit

extension MistDemoConfig {
  /// Create a test configuration with default values
  internal init() async throws {
    let configuration = try await MistDemoConfiguration()
    self = try await MistDemoConfig(configuration: configuration)
  }

  /// Create a test configuration that injects a raw `environment`
  /// string into the underlying provider. Used to exercise the
  /// env-validation logic with values the typed `environment:`
  /// initializer cannot express (e.g. `"PRODUCTION"`, `"staging"`).
  ///
  /// Only the keys whose parsing this init aims to exercise are set;
  /// `database` is left unset so it falls through to the production
  /// parser's default and cannot affect environment-test semantics.
  internal init(rawEnvironment: String) async throws {
    self = try await MistDemoConfig(
      configuration: Self.makeConfiguration([
        (MistDemoKeys.cloudKit.containerID, "iCloud.com.test.App"),
        (MistDemoKeys.Auth.apiToken, "test-api-token"),
        (MistDemoKeys.cloudKit.environment, rawEnvironment),
      ])
    )
  }

  /// Create a test configuration with custom values
  internal init(
    containerIdentifier: String = "iCloud.com.test.App",
    apiToken: String = "test-api-token",
    environment: MistKit.Environment = .development,
    database: MistKit.Database = .private,
    webAuthToken: String? = nil,
    keyID: String? = nil,
    privateKey: String? = nil,
    privateKeyFile: String? = nil,
    host: String = "127.0.0.1",
    port: Int = 8_080,
    authTimeout: Double = 300,
    skipAuth: Bool = false,
    testAllAuth: Bool = false,
    testApiOnly: Bool = false,
    testAdaptive: Bool = false,
    testServerToServer: Bool = false,
    badCredentials: Bool = false
  ) async throws {
    var values: [(key: any ConfigurationKey, value: String)] = [
      (MistDemoKeys.cloudKit.containerID, containerIdentifier),
      (MistDemoKeys.Auth.apiToken, apiToken),
      (
        MistDemoKeys.cloudKit.environment,
        environment == .production ? "production" : "development"
      ),
      (MistDemoKeys.Server.database, database.pathSegment),
      (MistDemoKeys.Server.host, host),
      (MistDemoKeys.Server.port, String(port)),
      (MistDemoKeys.Server.authTimeout, String(Int(authTimeout))),
      (MistDemoKeys.Auth.skipAuth, String(skipAuth)),
      (MistDemoKeys.AuthModes.testAllAuth, String(testAllAuth)),
      (MistDemoKeys.AuthModes.testAPIOnly, String(testApiOnly)),
      (MistDemoKeys.AuthModes.testAdaptive, String(testAdaptive)),
      (MistDemoKeys.AuthModes.testServerToServer, String(testServerToServer)),
      (MistDemoKeys.Auth.badCredentials, String(badCredentials)),
    ]

    if let webAuthToken { values.append((MistDemoKeys.Auth.webAuthToken, webAuthToken)) }
    if let keyID { values.append((MistDemoKeys.cloudKit.keyID, keyID)) }
    if let privateKey { values.append((MistDemoKeys.cloudKit.privateKey, privateKey)) }
    // Previously seeded `private.key.file`, a key production never read, so the
    // `privateKeyFile:` argument silently did nothing.
    if let privateKeyFile {
      values.append((MistDemoKeys.cloudKit.privateKeyPath, privateKeyFile))
    }

    self = try await MistDemoConfig(configuration: Self.makeConfiguration(values))
  }

  private static func makeConfiguration(
    _ values: [(key: any ConfigurationKey, value: String)]
  ) -> MistDemoConfiguration {
    MistDemoConfiguration.forTesting(values)
  }
}

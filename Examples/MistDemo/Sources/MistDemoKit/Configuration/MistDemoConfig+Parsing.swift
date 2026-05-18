//
//  MistDemoConfig+Parsing.swift
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

internal import MistKit

extension MistDemoConfig {
  internal struct CoreConfig {
    internal let containerIdentifier: String
    internal let apiToken: String
    internal let environment: MistKit.Environment
  }

  internal struct AuthConfig {
    internal let webAuthToken: String?
    internal let keyID: String?
    internal let privateKey: String?
    internal let privateKeyFile: String?
  }

  internal struct ServerConfig {
    internal let host: String
    internal let port: Int
    internal let authTimeout: Double
  }

  internal struct FlagConfig {
    internal let skipAuth: Bool
    internal let testAllAuth: Bool
    internal let testApiOnly: Bool
    internal let testAdaptive: Bool
    internal let testServerToServer: Bool
    internal let badCredentials: Bool
  }

  internal static func parseCoreConfig(
    _ config: MistDemoConfiguration
  ) throws -> CoreConfig {
    let containerIdentifier =
      config.string(
        forKey: "container.identifier",
        default: MistDemoConstants.Defaults.containerIdentifier
      ) ?? MistDemoConstants.Defaults.containerIdentifier

    let apiToken =
      config.string(
        forKey: "api.token",
        default: "",
        isSecret: true
      ) ?? ""

    let defaultEnv = MistKit.Environment.development.rawValue
    let envString =
      config.string(forKey: "environment", default: defaultEnv) ?? defaultEnv
    guard let environment = MistKit.Environment(caseInsensitive: envString) else {
      throw ConfigurationError.invalidEnvironment(envString)
    }

    return CoreConfig(
      containerIdentifier: containerIdentifier,
      apiToken: apiToken,
      environment: environment
    )
  }

  internal static func parseAuthConfig(
    _ config: MistDemoConfiguration
  ) -> AuthConfig {
    AuthConfig(
      webAuthToken: config.string(
        forKey: "web.auth.token",
        isSecret: true
      ),
      keyID: config.string(forKey: "key.id"),
      privateKey: config.string(
        forKey: "private.key",
        isSecret: true
      ),
      privateKeyFile: config.string(
        forKey: "private.key.path"
      )
    )
  }

  internal static func parseServerConfig(
    _ config: MistDemoConfiguration
  ) -> ServerConfig {
    let host =
      config.string(
        forKey: "host",
        default: "127.0.0.1"
      ) ?? "127.0.0.1"

    let port =
      config.int(
        forKey: "port",
        default: 8_080
      ) ?? 8_080

    let authTimeout = Double(
      config.int(
        forKey: "auth.timeout",
        default: 300
      ) ?? 300
    )

    return ServerConfig(
      host: host,
      port: port,
      authTimeout: authTimeout
    )
  }

  internal static func parseFlags(
    _ config: MistDemoConfiguration
  ) -> FlagConfig {
    FlagConfig(
      skipAuth: config.bool(
        forKey: "skip.auth",
        default: false
      ),
      testAllAuth: config.bool(
        forKey: "test.all.auth",
        default: false
      ),
      testApiOnly: config.bool(
        forKey: "test.api.only",
        default: false
      ),
      testAdaptive: config.bool(
        forKey: "test.adaptive",
        default: false
      ),
      testServerToServer: config.bool(
        forKey: "test.server.to.server",
        default: false
      ),
      badCredentials: config.bool(
        forKey: "bad.credentials",
        default: false
      )
    )
  }
}

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
internal import MistKitConfiguration

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
      config.read(MistDemoKeys.cloudKit.containerID)

    let apiToken =
      config.read(MistDemoKeys.Auth.apiToken)

    let defaultEnv = MistDemoConstants.Defaults.environment
    let envString =
      config.read(MistDemoKeys.cloudKit.environment) ?? defaultEnv
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
      webAuthToken: config.read(MistDemoKeys.Auth.webAuthToken),
      keyID: config.read(MistDemoKeys.cloudKit.keyID),
      privateKey: config.read(MistDemoKeys.cloudKit.privateKey),
      privateKeyFile: config.read(MistDemoKeys.cloudKit.privateKeyPath)
    )
  }

  internal static func parseServerConfig(
    _ config: MistDemoConfiguration
  ) -> ServerConfig {
    let host =
      config.read(MistDemoKeys.Server.host)

    let port =
      config.read(MistDemoKeys.Server.port)

    let authTimeout = Double(
      config.read(MistDemoKeys.Server.authTimeout)
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
      skipAuth: config.read(MistDemoKeys.Auth.skipAuth),
      testAllAuth: config.read(MistDemoKeys.AuthModes.testAllAuth),
      testApiOnly: config.read(MistDemoKeys.AuthModes.testAPIOnly),
      testAdaptive: config.read(MistDemoKeys.AuthModes.testAdaptive),
      testServerToServer: config.read(MistDemoKeys.AuthModes.testServerToServer),
      badCredentials: config.read(MistDemoKeys.Auth.badCredentials)
    )
  }
}

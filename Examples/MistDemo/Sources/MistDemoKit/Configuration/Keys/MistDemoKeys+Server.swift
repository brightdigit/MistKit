//
//  MistDemoKeys+Server.swift
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

extension MistDemoKeys {
  /// Local web-server and browser keys used by `web` and the auth-token flows.
  internal enum Server {
    /// `--database` / `CLOUDKIT_DATABASE`.
    ///
    /// Defaults to `public`, matching the historical runtime default. The former
    /// `MistDemoConstants.Defaults.database` constant said `private`, contradicted the
    /// code, and was never read.
    internal static let database = ConfigKey<String>(
      "database",
      envPrefix: MistDemoKeys.envPrefix,
      default: "public"
    )

    /// `--host` / `CLOUDKIT_HOST`.
    internal static let host = ConfigKey<String>(
      "host",
      envPrefix: MistDemoKeys.envPrefix,
      default: MistDemoConstants.Defaults.host
    )

    /// `--port` / `CLOUDKIT_PORT`.
    internal static let port = ConfigKey<Int>(
      "port",
      envPrefix: MistDemoKeys.envPrefix,
      default: MistDemoConstants.Defaults.port
    )

    /// `--auth-timeout` / `CLOUDKIT_AUTH_TIMEOUT`, in seconds.
    internal static let authTimeout = ConfigKey<Int>(
      "auth.timeout",
      envPrefix: MistDemoKeys.envPrefix,
      default: 300
    )

    /// `--browser` / `CLOUDKIT_BROWSER`.
    internal static let browser = ConfigKey<Bool>(
      "browser",
      envPrefix: MistDemoKeys.envPrefix,
      default: false
    )

    /// `--no-browser` / `CLOUDKIT_NO_BROWSER`.
    internal static let noBrowser = ConfigKey<Bool>(
      "no.browser",
      envPrefix: MistDemoKeys.envPrefix,
      default: false
    )
  }
}

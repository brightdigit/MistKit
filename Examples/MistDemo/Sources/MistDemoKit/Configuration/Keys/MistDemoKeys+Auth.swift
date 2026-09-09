//
//  MistDemoKeys+Auth.swift
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
  /// Web-auth and sharee credential keys.
  ///
  /// These are MistDemo-only — neither BushelCloud nor CelestraCloud models web auth —
  /// so they keep their historical bases plus ``MistDemoKeys/envPrefix``.
  internal enum Auth {
    /// `--api-token` / `CLOUDKIT_API_TOKEN`.
    internal static let apiToken = ConfigKey<String>(
      "api.token",
      envPrefix: MistDemoKeys.envPrefix,
      default: "",
      isSecret: true
    )

    /// `--web-auth-token` / `CLOUDKIT_WEB_AUTH_TOKEN`.
    internal static let webAuthToken = OptionalConfigKey<String>(
      "web.auth.token",
      envPrefix: MistDemoKeys.envPrefix,
      isSecret: true
    )

    /// `--sharee-web-auth-token` / `CLOUDKIT_SHAREE_WEB_AUTH_TOKEN`.
    internal static let shareeWebAuthToken = OptionalConfigKey<String>(
      "sharee.web.auth.token",
      envPrefix: MistDemoKeys.envPrefix,
      isSecret: true
    )

    /// `--sharee-email` / `CLOUDKIT_SHAREE_EMAIL`.
    internal static let shareeEmail = OptionalConfigKey<String>(
      "sharee.email",
      envPrefix: MistDemoKeys.envPrefix
    )

    /// `--reset-auth` / `CLOUDKIT_RESET_AUTH`.
    internal static let resetAuth = ConfigKey<Bool>(
      "reset.auth",
      envPrefix: MistDemoKeys.envPrefix,
      default: false
    )

    /// `--skip-auth` / `CLOUDKIT_SKIP_AUTH`.
    internal static let skipAuth = ConfigKey<Bool>(
      "skip.auth",
      envPrefix: MistDemoKeys.envPrefix,
      default: false
    )

    /// `--bad-credentials` / `CLOUDKIT_BAD_CREDENTIALS`.
    internal static let badCredentials = ConfigKey<Bool>(
      "bad.credentials",
      envPrefix: MistDemoKeys.envPrefix,
      default: false
    )
  }
}

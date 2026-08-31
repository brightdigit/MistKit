//
//  MistDemoKeys+AuthModes.swift
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
  /// Flags selecting which authentication modes the demo exercises.
  internal enum AuthModes {
    /// `--test-all-auth` / `CLOUDKIT_TEST_ALL_AUTH`.
    internal static let testAllAuth = ConfigKey<Bool>(
      "test.all.auth", envPrefix: MistDemoKeys.envPrefix, default: false
    )

    /// `--test-api-only` / `CLOUDKIT_TEST_API_ONLY`.
    internal static let testAPIOnly = ConfigKey<Bool>(
      "test.api.only", envPrefix: MistDemoKeys.envPrefix, default: false
    )

    /// `--test-adaptive` / `CLOUDKIT_TEST_ADAPTIVE`.
    internal static let testAdaptive = ConfigKey<Bool>(
      "test.adaptive", envPrefix: MistDemoKeys.envPrefix, default: false
    )

    /// `--test-server-to-server` / `CLOUDKIT_TEST_SERVER_TO_SERVER`.
    internal static let testServerToServer = ConfigKey<Bool>(
      "test.server.to.server", envPrefix: MistDemoKeys.envPrefix, default: false
    )
  }
}

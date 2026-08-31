//
//  MistDemoKeys+CloudKit.swift
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
  /// CloudKit container, credential and environment keys.
  internal enum CloudKit {
    /// `--cloudkit-container-id` / `CLOUDKIT_CONTAINER_ID`.
    ///
    /// Previously based on `container.identifier`, which resolved to
    /// `CLOUDKIT_CONTAINER_IDENTIFIER` — a variable nothing set. CI and the deployment
    /// guide have always supplied `CLOUDKIT_CONTAINER_ID`, so this base repairs a
    /// value that was silently ignored.
    internal static let containerID = ConfigKey<String>(
      "cloudkit.container-id",
      default: MistDemoConstants.Defaults.containerIdentifier
    )

    /// `--cloudkit-key-id` / `CLOUDKIT_KEY_ID`. Server-to-server key ID.
    internal static let keyID = OptionalConfigKey<String>("cloudkit.key-id", isSecret: true)

    /// `--cloudkit-private-key` / `CLOUDKIT_PRIVATE_KEY`. Inline PEM.
    internal static let privateKey = OptionalConfigKey<String>(
      "cloudkit.private-key",
      isSecret: true
    )

    /// `--cloudkit-private-key-path` / `CLOUDKIT_PRIVATE_KEY_PATH`. Path to a PEM file.
    internal static let privateKeyPath = OptionalConfigKey<String>(
      "cloudkit.private-key-path",
      isSecret: true
    )

    /// `--cloudkit-environment` / `CLOUDKIT_ENVIRONMENT`.
    internal static let environment = ConfigKey<String>(
      "cloudkit.environment",
      default: MistDemoConstants.Defaults.environment
    )
  }
}

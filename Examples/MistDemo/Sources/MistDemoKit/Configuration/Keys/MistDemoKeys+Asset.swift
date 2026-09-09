//
//  MistDemoKeys+Asset.swift
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
  /// Asset upload and re-reference keys.
  internal enum Asset {
    /// `--file` / `CLOUDKIT_FILE`.
    internal static let file = OptionalConfigKey<String>(
      "file", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--field-name` / `CLOUDKIT_FIELD_NAME`.
    internal static let fieldName = ConfigKey<String>(
      "field-name", envPrefix: MistDemoKeys.envPrefix, default: "image"
    )

    /// `--source-record` / `CLOUDKIT_SOURCE_RECORD`.
    internal static let sourceRecord = OptionalConfigKey<String>(
      "source-record", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--asset-field` / `CLOUDKIT_ASSET_FIELD`.
    internal static let assetField = OptionalConfigKey<String>(
      "asset-field", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--target-record` / `CLOUDKIT_TARGET_RECORD`.
    internal static let targetRecord = OptionalConfigKey<String>(
      "target-record", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--target-asset-field` / `CLOUDKIT_TARGET_ASSET_FIELD`.
    internal static let targetAssetField = OptionalConfigKey<String>(
      "target-asset-field", envPrefix: MistDemoKeys.envPrefix
    )
  }
}

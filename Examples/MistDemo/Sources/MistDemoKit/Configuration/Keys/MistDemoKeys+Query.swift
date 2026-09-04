//
//  MistDemoKeys+Query.swift
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
  /// Query, zone-selection and pagination keys.
  internal enum Query {
    /// `--zone` / `CLOUDKIT_ZONE`.
    internal static let zone = ConfigKey<String>(
      "zone", envPrefix: MistDemoKeys.envPrefix, default: MistDemoConstants.Defaults.zone
    )

    /// `--zone` without a default, for commands where it is optional.
    internal static let optionalZone = OptionalConfigKey<String>(
      "zone", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--zone-owner` / `CLOUDKIT_ZONE_OWNER`, the `ownerName` of a shared zone.
    internal static let zoneOwner = OptionalConfigKey<String>(
      "zone.owner", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--zone-name` / `CLOUDKIT_ZONE_NAME`.
    internal static let zoneName = OptionalConfigKey<String>(
      "zone.name", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--zone-names` / `CLOUDKIT_ZONE_NAMES`, comma separated.
    internal static let zoneNames = ConfigKey<String>(
      "zone.names",
      envPrefix: MistDemoKeys.envPrefix,
      default: MistDemoConstants.Defaults.zone
    )

    /// `--zones-include-default` / `CLOUDKIT_ZONES_INCLUDE_DEFAULT`.
    internal static let zonesIncludeDefault = ConfigKey<Bool>(
      "zones.include-default", envPrefix: MistDemoKeys.envPrefix, default: false
    )

    /// `--zone-wide` / `CLOUDKIT_ZONE_WIDE`, query across all zones.
    internal static let zoneWide = OptionalConfigKey<Bool>(
      "zone.wide", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--filter` / `CLOUDKIT_FILTER`, pipe separated.
    internal static let filter = OptionalConfigKey<String>(
      "filter", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--sort` / `CLOUDKIT_SORT`.
    internal static let sort = OptionalConfigKey<String>(
      "sort", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--limit` / `CLOUDKIT_LIMIT`, with a default for `query`.
    internal static let limit = ConfigKey<Int>(
      "limit",
      envPrefix: MistDemoKeys.envPrefix,
      default: MistDemoConstants.Defaults.queryLimit
    )

    /// `--limit` without a default, for the change-tracking commands.
    internal static let optionalLimit = OptionalConfigKey<Int>(
      "limit", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--offset` / `CLOUDKIT_OFFSET`.
    internal static let offset = ConfigKey<Int>(
      "offset", envPrefix: MistDemoKeys.envPrefix, default: 0
    )

    /// `--continuation-marker` / `CLOUDKIT_CONTINUATION_MARKER`.
    internal static let continuationMarker = OptionalConfigKey<String>(
      "continuation.marker", envPrefix: MistDemoKeys.envPrefix
    )
  }
}

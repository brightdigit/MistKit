//
//  MistDemoKeys.swift
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

/// Typed configuration keys for MistDemo.
///
/// Every key resolves to a command-line flag and an environment variable:
///
/// - **CloudKit credential keys** come from ``CloudKitConfigurationKeys`` (shared with
///   MistKitConfiguration, BushelCloud and CelestraCloud).
/// - **Every other key** keeps its historical base and passes ``envPrefix``, faithfully
///   reproducing the blanket `prefixKeys(with: "cloudkit")` the provider stack used to
///   apply to the whole key space. Bases stay unchanged so no flag or variable moves.
///
/// Bases must be **dash-case** within a component (`cloudkit.key-id`, never
/// `cloudkit.key_id`): `CLIKeyEncoder` joins components verbatim, so an underscore
/// survives into an unusable flag and silently defeats secret redaction.
internal enum MistDemoKeys {
  /// Environment-variable prefix applied to every non-CloudKit key.
  internal static let envPrefix = "CLOUDKIT"

  /// CloudKit credential keys with MistDemo's container default.
  ///
  /// `environment` is optional on the package key; callers apply
  /// ``MistDemoConstants/Defaults/environment`` when the value is absent.
  internal static let cloudKit = CloudKitConfigurationKeys(
    defaultContainerID: MistDemoConstants.Defaults.containerIdentifier
  )
}

//
//  MistDemoKeys+Subscription.swift
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
  /// Subscription and push-token keys.
  internal enum Subscription {
    /// `--subscription-id` / `CLOUDKIT_SUBSCRIPTION_ID`.
    internal static let subscriptionID = OptionalConfigKey<String>(
      "subscription-id", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--subscription-ids` / `CLOUDKIT_SUBSCRIPTION_IDS`, comma separated.
    internal static let subscriptionIDs = ConfigKey<String>(
      "subscription-ids", envPrefix: MistDemoKeys.envPrefix, default: ""
    )

    /// `--fires-on` / `CLOUDKIT_FIRES_ON`, comma separated.
    internal static let firesOn = ConfigKey<String>(
      "fires-on", envPrefix: MistDemoKeys.envPrefix, default: "create,update,delete"
    )

    /// `--operation` / `CLOUDKIT_OPERATION`.
    internal static let operation = ConfigKey<String>(
      "operation", envPrefix: MistDemoKeys.envPrefix, default: "create"
    )

    /// `--apns-token` / `CLOUDKIT_APNS_TOKEN`.
    internal static let apnsToken = OptionalConfigKey<String>(
      "apns-token", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--apns-environment` / `CLOUDKIT_APNS_ENVIRONMENT`.
    internal static let apnsEnvironment = OptionalConfigKey<String>(
      "apns-environment", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--client-id` / `CLOUDKIT_CLIENT_ID`.
    internal static let clientID = OptionalConfigKey<String>(
      "client-id", envPrefix: MistDemoKeys.envPrefix
    )
  }
}

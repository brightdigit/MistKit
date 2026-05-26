//
//  NotificationInfo.swift
//  MistKit
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

internal import MistKitOpenAPI

// `Bool?` carries an intentional tri-state on these notification flags:
// `nil` means "don't send this field; let CloudKit apply its default"
// (`shouldBadge=false`, `shouldSendContentAvailable=false`). Defaulting
// to non-optional would force callers to pick a wire-level value when
// they really want server-side defaults.
// swiftlint:disable discouraged_optional_boolean

/// How CloudKit shapes the push notification produced by a subscription.
///
/// Mirrors `CloudKit.NotificationInfo` from the CloudKit JS reference.
/// Every field is optional — CloudKit applies its own defaults
/// (`shouldBadge=false`, `shouldSendContentAvailable=false`, no alert
/// body) when a field is absent. Pass only the fields you want the
/// server to honor.
public struct NotificationInfo: Codable, Hashable, Sendable {
  /// The text of the alert message.
  public let alertBody: String?
  /// A key to a localized alert message.
  public let alertLocalizationKey: String?
  /// Strings that appear as variables if ``alertLocalizationKey`` is a
  /// format specifier.
  public let alertLocalizationArgs: [String]?
  /// A key to the localized title of the alert's action button.
  public let alertActionLocalizationKey: String?
  /// The filename of the image to use as the launch image.
  public let alertLaunchImage: String?
  /// The filename of the sound to play when the notification arrives.
  public let soundName: String?
  /// Whether the app icon's badge should be incremented. Server default
  /// is `false` when this is `nil`.
  public let shouldBadge: Bool?
  /// Whether the notification should mark new content as available
  /// (silent background fetch). Server default is `false` when this
  /// is `nil`.
  public let shouldSendContentAvailable: Bool?
  /// Names of record fields whose values should be included in the
  /// notification payload.
  public let additionalFields: [String]?
  /// The notification category (UN actionable category identifier).
  public let category: String?

  /// Creates a new `NotificationInfo`. Every parameter is optional —
  /// omit anything you want CloudKit to default.
  public init(
    alertBody: String? = nil,
    alertLocalizationKey: String? = nil,
    alertLocalizationArgs: [String]? = nil,
    alertActionLocalizationKey: String? = nil,
    alertLaunchImage: String? = nil,
    soundName: String? = nil,
    shouldBadge: Bool? = nil,
    shouldSendContentAvailable: Bool? = nil,
    additionalFields: [String]? = nil,
    category: String? = nil
  ) {
    self.alertBody = alertBody
    self.alertLocalizationKey = alertLocalizationKey
    self.alertLocalizationArgs = alertLocalizationArgs
    self.alertActionLocalizationKey = alertActionLocalizationKey
    self.alertLaunchImage = alertLaunchImage
    self.soundName = soundName
    self.shouldBadge = shouldBadge
    self.shouldSendContentAvailable = shouldSendContentAvailable
    self.additionalFields = additionalFields
    self.category = category
  }
}

// swiftlint:enable discouraged_optional_boolean

// MARK: - Internal Conversion
extension NotificationInfo {
  internal var schema: Components.Schemas.NotificationInfo {
    Components.Schemas.NotificationInfo(
      alertBody: alertBody,
      alertLocalizationKey: alertLocalizationKey,
      alertLocalizationArgs: alertLocalizationArgs,
      alertActionLocalizationKey: alertActionLocalizationKey,
      alertLaunchImage: alertLaunchImage,
      soundName: soundName,
      shouldBadge: shouldBadge,
      shouldSendContentAvailable: shouldSendContentAvailable,
      additionalFields: additionalFields,
      category: category
    )
  }

  internal init(from schema: Components.Schemas.NotificationInfo) {
    self.init(
      alertBody: schema.alertBody,
      alertLocalizationKey: schema.alertLocalizationKey,
      alertLocalizationArgs: schema.alertLocalizationArgs,
      alertActionLocalizationKey: schema.alertActionLocalizationKey,
      alertLaunchImage: schema.alertLaunchImage,
      soundName: schema.soundName,
      shouldBadge: schema.shouldBadge,
      shouldSendContentAvailable: schema.shouldSendContentAvailable,
      additionalFields: schema.additionalFields,
      category: schema.category
    )
  }
}

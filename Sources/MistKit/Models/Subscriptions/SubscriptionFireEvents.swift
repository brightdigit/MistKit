//
//  SubscriptionFireEvents.swift
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

/// The set of record-change events that cause a query subscription
/// to fire a push notification.
///
/// Mirrors native `CKQuerySubscriptionOptions` (minus `firesOnce`,
/// which MistKit models as a separate `Bool?` to match the CloudKit
/// Web Services wire fields `firesOn` and `firesOnce`).
///
/// Set semantics matches CloudKit's behavior: two query subscriptions
/// sharing `(recordType, firesOn)` collide regardless of
/// `subscriptionID` (see GH brightdigit/MistKit#387), and the wire
/// format is JSON `["create","update","delete"]`.
public struct SubscriptionFireEvents: OptionSet, Sendable, Hashable {
  // MARK: - Public

  public let rawValue: Int

  /// Fire when a matching record is created.
  public static let create = SubscriptionFireEvents(rawValue: 1 << 0)
  /// Fire when a matching record is updated.
  public static let update = SubscriptionFireEvents(rawValue: 1 << 1)
  /// Fire when a matching record is deleted.
  public static let delete = SubscriptionFireEvents(rawValue: 1 << 2)

  /// All three record-change events.
  public static let all: SubscriptionFireEvents = [.create, .update, .delete]

  // MARK: - Lifecycle

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
}

// MARK: - Codable (wire format: array of strings)

extension SubscriptionFireEvents: Codable {
  private static let createWire = "create"
  private static let updateWire = "update"
  private static let deleteWire = "delete"

  public init(from decoder: any Decoder) throws {
    let strings = try [String](from: decoder)
    var events: SubscriptionFireEvents = []
    for string in strings {
      switch string {
      case Self.createWire: events.insert(.create)
      case Self.updateWire: events.insert(.update)
      case Self.deleteWire: events.insert(.delete)
      default:
        throw DecodingError.dataCorrupted(
          .init(
            codingPath: decoder.codingPath,
            debugDescription: "Unknown SubscriptionFireEvent wire value: \(string)"
          )
        )
      }
    }
    self = events
  }

  public func encode(to encoder: any Encoder) throws {
    var strings: [String] = []
    if contains(.create) { strings.append(Self.createWire) }
    if contains(.update) { strings.append(Self.updateWire) }
    if contains(.delete) { strings.append(Self.deleteWire) }
    try strings.encode(to: encoder)
  }
}

// MARK: - OpenAPI Schema Bridge

extension SubscriptionFireEvents {
  /// The set's wire representation as an array of the OpenAPI-generated
  /// per-event enum. Sort order is deterministic (create, update,
  /// delete) so encoding is stable for tests and HTTP caches.
  internal var schemaValues: [Components.Schemas.Subscription.firesOnPayloadPayload] {
    var values: [Components.Schemas.Subscription.firesOnPayloadPayload] = []
    if contains(.create) { values.append(.create) }
    if contains(.update) { values.append(.update) }
    if contains(.delete) { values.append(.delete) }
    return values
  }

  internal init(schemaValues: [Components.Schemas.Subscription.firesOnPayloadPayload]) {
    var events: SubscriptionFireEvents = []
    for value in schemaValues {
      switch value {
      case .create: events.insert(.create)
      case .update: events.insert(.update)
      case .delete: events.insert(.delete)
      }
    }
    self = events
  }
}

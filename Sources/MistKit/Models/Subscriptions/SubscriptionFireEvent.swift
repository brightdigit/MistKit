//
//  SubscriptionFireEvent.swift
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

/// A record-change event that causes a subscription to fire a push.
///
/// A subscription's `firesOn` set selects which of these trigger a notification.
public enum SubscriptionFireEvent: String, Codable, Sendable, CaseIterable {
  /// Fire when a matching record is created.
  case create
  /// Fire when a matching record is updated.
  case update
  /// Fire when a matching record is deleted.
  case delete
}

// MARK: - Internal Conversion
extension SubscriptionFireEvent {
  internal var schemaValue: Components.Schemas.Subscription.firesOnPayloadPayload {
    switch self {
    case .create:
      return .create
    case .update:
      return .update
    case .delete:
      return .delete
    }
  }

  internal init(from payload: Components.Schemas.Subscription.firesOnPayloadPayload) {
    switch payload {
    case .create:
      self = .create
    case .update:
      self = .update
    case .delete:
      self = .delete
    }
  }
}

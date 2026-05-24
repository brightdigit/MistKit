//
//  SubscriptionOperation.swift
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

/// A create / update / delete operation against a CloudKit subscription, used by
/// ``CloudKitService/modifySubscriptions(_:database:)``.
public enum SubscriptionOperation: Sendable {
  /// Create the given subscription.
  case create(SubscriptionInfo)

  /// Update the given subscription.
  case update(SubscriptionInfo)

  /// Delete the subscription with the given identifier.
  case delete(subscriptionID: String)
}

// MARK: - Internal Conversion
extension Components.Schemas.SubscriptionOperation {
  internal init(from operation: SubscriptionOperation) {
    switch operation {
    case .create(let info):
      self.init(operationType: .create, subscription: info.schema)
    case .update(let info):
      self.init(operationType: .update, subscription: info.schema)
    case .delete(let subscriptionID):
      self.init(
        operationType: .delete,
        subscription: Components.Schemas.Subscription(subscriptionID: subscriptionID)
      )
    }
  }
}

//
//  SubscriptionTarget.swift
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

/// Phantom target tagging an ``OperationFailure`` (or ``OperationResult``) as
/// belonging to a per-subscription CloudKit batch (`modifySubscriptions`).
public enum SubscriptionTarget: OperationFailureTarget {
  /// Lifts a per-subscription failure into
  /// ``CloudKitError/subscriptionOperationFailed(_:)``.
  public static func wrap(
    _ failure: OperationFailure<SubscriptionTarget>
  ) -> CloudKitError {
    .subscriptionOperationFailed(failure)
  }
}

extension OperationFailure where Target == SubscriptionTarget {
  /// The exact `reason` string CloudKit currently returns when a
  /// `subscriptions/modify` create collides with an existing subscription
  /// whose query + `firesOn` already match. The match is intentionally
  /// **exact** — the reason is server-controlled and a loose substring
  /// match risks false positives on unrelated future `INTERNAL_ERROR`
  /// variants. Revisit only if `mistdemo probe-duplicate-subscription`
  /// surfaces wording variants.
  internal static let duplicateMarker = "could not find subscription we just created"

  /// The ID of the subscription the operation failed on.
  ///
  /// A named alias for ``OperationFailure/identifier`` scoped to the
  /// subscription target, matching CloudKit's `subscriptionID` wire field.
  public var subscriptionID: String { identifier }

  /// `true` when CloudKit returned `INTERNAL_ERROR` with the exact reason
  /// string that, in practice, signals another subscription with matching
  /// properties (query/`firesOn` — *not* `subscriptionID`) already exists.
  ///
  /// **This is a hint, not a guarantee.** CloudKit's wire-level error code
  /// is `INTERNAL_ERROR`; the duplicate interpretation is MistKit's
  /// inference from the reason string. Use this to surface a helpful
  /// suggestion ("a matching subscription may already exist — try
  /// `listSubscriptions` to find it") rather than to short-circuit retry
  /// logic with certainty.
  public var isLikelyDuplicate: Bool {
    serverErrorCode == .internalError && reason == Self.duplicateMarker
  }

  internal init(from schema: Components.Schemas.SubscriptionOperationFailure) {
    self.init(identifier: schema.value2.subscriptionID, common: schema.value1)
  }
}

extension OperationResult
where Success == SubscriptionInfo, Target == SubscriptionTarget {
  /// Converts a per-item entry from a `subscriptions/modify` response.
  ///
  /// Returns `nil` when CloudKit echoes a deleted subscription as a bare
  /// `{ subscriptionID }` with no `subscriptionType` — a deletion
  /// acknowledgement, not a result, so callers skip it rather than treating
  /// the missing type as a conversion failure.
  internal init?(
    from item: Components.Schemas.SubscriptionsModifyResponse.subscriptionsPayloadPayload
  ) throws(ConversionError) {
    switch item {
    case .SubscriptionOperationFailure(let failure):
      self = .failure(OperationFailure(from: failure))
    case .Subscription(let subscription):
      guard subscription.subscriptionType != nil else {
        return nil
      }
      self = .success(try SubscriptionInfo(from: subscription))
    }
  }
}

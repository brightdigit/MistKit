//
//  SubscriptionResult.swift
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

/// The outcome of a single operation in a `modifySubscriptions` batch.
///
/// CloudKit returns per-operation results inline in the response
/// `subscriptions` array: a successful create/update yields a subscription,
/// while a failed one yields an error describing what went wrong.
/// `SubscriptionResult` models that union — the subscriptions analogue of
/// ``RecordResult`` — so no per-subscription failure is silently dropped.
///
/// ```swift
/// let results = try await service.modifySubscriptions(operations, database: .private)
/// for result in results {
///   switch result {
///   case .success(let subscription): print("saved \(subscription.subscriptionID)")
///   case .failure(let error):        print("failed: \(error.serverErrorCode.rawValue)")
///   }
/// }
/// ```
///
/// - Note: A *deletion* acknowledgement (CloudKit echoes a bare
///   `{ subscriptionID }` with no type) is neither a success subscription nor a
///   failure, so it is omitted from the results rather than represented here.
public enum SubscriptionResult: Sendable {
  /// The operation succeeded and CloudKit returned the resulting subscription.
  case success(SubscriptionInfo)
  /// The operation failed; the associated ``SubscriptionOperationFailure``
  /// describes the failure.
  case failure(SubscriptionOperationFailure)

  /// Returns the subscription for a successful result, or throws
  /// ``CloudKitError/subscriptionOperationFailed(_:)`` for a failure.
  public func get() throws(CloudKitError) -> SubscriptionInfo {
    switch self {
    case .success(let subscription):
      return subscription
    case .failure(let error):
      throw CloudKitError.subscriptionOperationFailed(error)
    }
  }
}

//
//  CloudKitService+ModifySubscriptions.swift
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

extension CloudKitService {
  /// Create, update, or delete subscriptions in a single request.
  ///
  /// - Parameters:
  ///   - operations: The subscription operations to apply.
  ///   - database: The CloudKit database scope to modify.
  /// - Returns: The subscriptions returned by CloudKit (created/updated
  ///   subscriptions; deletions are typically omitted).
  /// - Throws: ``CloudKitError`` if the request fails.
  public func modifySubscriptions(
    _ operations: [SubscriptionOperation],
    database: Database
  ) async throws(CloudKitError) -> [SubscriptionResult] {
    do {
      let client = try self.client(for: database)
      let response = try await client.modifySubscriptions(
        .init(
          path: Operations.modifySubscriptions.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: environment,
            database: database
          ),
          body: .json(
            .init(
              operations: operations.map {
                Components.Schemas.SubscriptionOperation(from: $0)
              }
            )
          )
        )
      )

      let subscriptionsData: Components.Schemas.SubscriptionsModifyResponse =
        try await responseProcessor.processModifySubscriptionsResponse(response)
      return try (subscriptionsData.subscriptions ?? []).compactMap {
        try SubscriptionResult(from: $0)
      }
    } catch {
      throw mapToCloudKitError(error, context: "modifySubscriptions")
    }
  }

  // The query factory's full DocC link can't wrap and exceeds the line limit;
  // disabling here keeps it a single resolvable token.
  // swiftlint:disable line_length
  /// Create a single subscription.
  ///
  /// Convenience wrapper over ``modifySubscriptions(_:database:)``. Build the
  /// `subscription` with
  /// ``SubscriptionInfo/query(subscriptionID:recordType:filters:sortBy:firesOn:firesOnce:notificationInfo:)``,
  /// ``SubscriptionInfo/zone(subscriptionID:zoneID:notificationInfo:)``, or
  /// ``SubscriptionInfo/database(subscriptionID:notificationInfo:)``.
  ///
  /// - Parameters:
  ///   - subscription: The subscription to create.
  ///   - database: The CloudKit database scope to modify.
  /// - Returns: The created subscription as returned by CloudKit.
  /// - Throws: ``CloudKitError/subscriptionLikelyDuplicate(_:)`` when CloudKit
  ///   returns `INTERNAL_ERROR` with its duplicate-subscription marker
  ///   reason (a *hint*, not a confirmed cause — see the case docs),
  ///   ``CloudKitError/subscriptionOperationFailed(_:)`` for any other
  ///   per-subscription failure, ``CloudKitError`` if the request fails,
  ///   or ``CloudKitError/invalidResponse`` if the response is empty.
  @discardableResult
  public func createSubscription(
    _ subscription: SubscriptionInfo,
    database: Database
  ) async throws(CloudKitError) -> SubscriptionInfo {
    // swiftlint:enable line_length
    let results = try await modifySubscriptions([.create(subscription)], database: database)
    guard let created = results.first else {
      throw CloudKitError.invalidResponse
    }
    if case .failure(let failure) = created, failure.isLikelyDuplicate {
      throw CloudKitError.subscriptionLikelyDuplicate(failure)
    }
    return try created.get()
  }

  /// Delete a single subscription by its identifier.
  ///
  /// - Parameters:
  ///   - id: The identifier of the subscription to delete.
  ///   - database: The CloudKit database scope to modify.
  /// - Throws: ``CloudKitError`` if the request fails.
  public func deleteSubscription(
    id: String,
    database: Database
  ) async throws(CloudKitError) {
    let results = try await modifySubscriptions([.delete(subscriptionID: id)], database: database)
    // A successful delete yields a (skipped) ack, so an empty result set means
    // success; surface any per-subscription failure CloudKit returned instead.
    for result in results {
      _ = try result.get()
    }
  }
}

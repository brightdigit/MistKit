//
//  CloudKitService+SubscriptionOperations.swift
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
  /// List all subscriptions in the target database.
  ///
  /// Subscriptions are the change triggers that produce push notifications;
  /// pair them with a registered APNs token
  /// (``createAPNsToken(environment:database:)`` /
  /// ``registerAPNsToken(_:database:)``) to receive pushes.
  ///
  /// - Parameter database: The CloudKit database scope to query.
  /// - Returns: Every subscription registered in the database.
  /// - Throws: ``CloudKitError`` if the request fails.
  public func listSubscriptions(
    database: Database
  ) async throws(CloudKitError) -> [SubscriptionInfo] {
    do {
      let client = try self.client(for: database)
      let response = try await client.listSubscriptions(
        .init(
          path: Operations.listSubscriptions.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: environment,
            database: database
          )
        )
      )

      let subscriptionsData: Components.Schemas.SubscriptionsListResponse =
        try await responseProcessor.processListSubscriptionsResponse(response)
      return try (subscriptionsData.subscriptions ?? []).map {
        try SubscriptionInfo(from: $0)
      }
    } catch {
      throw mapToCloudKitError(error, context: "listSubscriptions")
    }
  }

  /// Look up specific subscriptions by their identifiers.
  ///
  /// - Parameters:
  ///   - ids: The subscription identifiers to fetch.
  ///   - database: The CloudKit database scope to query.
  /// - Returns: The matching subscriptions.
  /// - Throws: ``CloudKitError`` if the request fails.
  public func lookupSubscriptions(
    ids: [String],
    database: Database
  ) async throws(CloudKitError) -> [SubscriptionInfo] {
    do {
      let client = try self.client(for: database)
      let response = try await client.lookupSubscriptions(
        .init(
          path: Operations.lookupSubscriptions.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: environment,
            database: database
          ),
          body: .json(
            .init(
              subscriptions: ids.map { .init(subscriptionID: $0) }
            )
          )
        )
      )

      let subscriptionsData: Components.Schemas.SubscriptionsLookupResponse =
        try await responseProcessor.processLookupSubscriptionsResponse(response)
      return try (subscriptionsData.subscriptions ?? []).map {
        try SubscriptionInfo(from: $0)
      }
    } catch {
      throw mapToCloudKitError(error, context: "lookupSubscriptions")
    }
  }
}

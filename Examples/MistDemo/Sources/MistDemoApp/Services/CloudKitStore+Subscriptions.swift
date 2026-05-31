//
//  CloudKitStore+Subscriptions.swift
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

#if canImport(CloudKit)
  internal import CloudKit
  internal import Foundation
  internal import MistDemoKit

  /// Display-friendly snapshot of a CKSubscription.
  internal struct SubscriptionRow: Identifiable, Hashable, Sendable {
    internal let id: String
    internal let kind: String
    internal let recordType: String?

    internal init(_ subscription: CKSubscription) {
      self.id = subscription.subscriptionID
      switch subscription {
      case let query as CKQuerySubscription:
        self.kind = "Query"
        self.recordType = query.recordType
      case let zone as CKRecordZoneSubscription:
        self.kind = "Zone (\(zone.zoneID.zoneName))"
        self.recordType = nil
      case is CKDatabaseSubscription:
        self.kind = "Database"
        self.recordType = nil
      default:
        self.kind = "Other"
        self.recordType = nil
      }
    }
  }

  extension CloudKitStore {
    /// List every CloudKit subscription registered on the selected
    /// database. Maps to `subscriptions/list` in the REST surface.
    internal func loadSubscriptions() async throws -> [SubscriptionRow] {
      let subscriptions = try await database.allSubscriptions()
      return subscriptions.map(SubscriptionRow.init).sorted { $0.id < $1.id }
    }

    /// Look up specific subscriptions by ID. Maps to `subscriptions/lookup`.
    internal func lookupSubscriptions(
      ids: [String]
    ) async throws -> [SubscriptionRow] {
      try await withCheckedThrowingContinuation { continuation in
        let operation = CKFetchSubscriptionsOperation(subscriptionIDs: ids)
        var rows: [SubscriptionRow] = []
        operation.perSubscriptionResultBlock = { _, result in
          if case .success(let subscription) = result {
            rows.append(SubscriptionRow(subscription))
          }
        }
        operation.fetchSubscriptionsResultBlock = { result in
          switch result {
          case .success:
            continuation.resume(returning: rows.sorted { $0.id < $1.id })
          case .failure(let error):
            continuation.resume(throwing: error)
          }
        }
        database.add(operation)
      }
    }

    /// Create a demo Note-query subscription so the subscriptions list has
    /// something visible. Uses a fixed `subscriptionID` so repeated taps are
    /// idempotent — CloudKit returns a conflict if it already exists, which
    /// the UI surfaces via the standard error path.
    internal func createDemoSubscription() async throws -> SubscriptionRow {
      let subscription = CKQuerySubscription(
        recordType: Note.recordType,
        predicate: NSPredicate(value: true),
        subscriptionID: "MistDemo.noteCreated",
        options: [.firesOnRecordCreation]
      )
      let info = CKSubscription.NotificationInfo()
      info.shouldSendContentAvailable = true
      subscription.notificationInfo = info
      let saved = try await database.save(subscription)
      return SubscriptionRow(saved)
    }

    /// Delete a subscription by ID.
    internal func deleteSubscription(id: String) async throws {
      _ = try await database.deleteSubscription(withID: id)
    }
  }
#endif

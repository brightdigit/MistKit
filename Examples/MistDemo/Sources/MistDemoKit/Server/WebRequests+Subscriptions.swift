//
//  WebRequests+Subscriptions.swift
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

internal import Foundation
internal import MistKit

extension WebRequests {
  /// `POST /api/subscriptions/modify`
  ///
  /// The browser sends one of two shapes, both handled here:
  /// - a bare CloudKit-JS subscription object (create), e.g.
  ///   `{ "subscriptionType": "query", "subscriptionID": "x",
  ///   "firesOn": ["create"], "query": { "recordType": "Note" } }`
  /// - a batch `{ "create": [...], "delete": [{ "subscriptionID": "x" }] }`.
  ///
  /// Both collapse into a single `[SubscriptionOperation]` via ``operations()``.
  internal struct ModifySubscriptions: Decodable {
    /// A subscription as posted by the browser (CloudKit JS shape).
    internal struct SubscriptionInput: Decodable, Sendable {
      internal struct QueryInput: Decodable, Sendable {
        internal let recordType: String?
      }
      internal struct ZoneInput: Decodable, Sendable {
        internal let zoneName: String?
      }

      internal let subscriptionID: String?
      internal let subscriptionType: String?
      internal let firesOn: [String]?
      internal let query: QueryInput?
      internal let zoneID: ZoneInput?
    }

    internal struct DeleteRef: Decodable, Sendable {
      internal let subscriptionID: String
    }

    private enum CodingKeys: String, CodingKey {
      case create
      case delete
      case database
    }

    internal let create: [SubscriptionInput]
    internal let delete: [DeleteRef]
    internal let database: MistKit.Database

    internal init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.delete =
        try container.decodeIfPresent([DeleteRef].self, forKey: .delete) ?? []

      if let explicit = try container.decodeIfPresent(
        [SubscriptionInput].self, forKey: .create
      ) {
        self.create = explicit
      } else if let single = try? SubscriptionInput(from: decoder),
        single.subscriptionType != nil
      {
        // Top-level bare subscription object (the create-panel shape).
        self.create = [single]
      } else {
        self.create = []
      }

      self.database = try WebRequests.decodeDatabase(
        from: container, forKey: .database
      )
    }

    /// Collapse the decoded create/delete inputs into MistKit operations.
    internal func operations() -> [SubscriptionOperation] {
      var operations: [SubscriptionOperation] = create.map { input in
        let firesOn = (input.firesOn ?? []).compactMap(SubscriptionFireEvent.init(rawValue:))
        if input.subscriptionType == "zone" {
          return .create(
            .zone(
              subscriptionID: input.subscriptionID ?? "",
              zoneID: ZoneID(zoneName: input.zoneID?.zoneName ?? ""),
              firesOn: firesOn
            )
          )
        }
        return .create(
          .query(
            subscriptionID: input.subscriptionID ?? "",
            recordType: input.query?.recordType ?? "",
            firesOn: firesOn
          )
        )
      }
      operations += delete.map { .delete(subscriptionID: $0.subscriptionID) }
      return operations
    }
  }
}

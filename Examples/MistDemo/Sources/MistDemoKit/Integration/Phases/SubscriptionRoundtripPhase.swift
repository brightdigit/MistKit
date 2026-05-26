//
//  SubscriptionRoundtripPhase.swift
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

/// Create a query subscription, confirm it appears via `subscriptions/list`
/// and `subscriptions/lookup`, then delete it — exercising all three
/// subscription endpoints in a single self-cleaning phase (mirroring
/// ``ZoneRoundtripPhase``).
internal struct SubscriptionRoundtripPhase: IntegrationPhase {
  internal typealias Input = NoState
  internal typealias Output = NoState

  internal static let title = "Create, list, lookup, and delete a subscription"
  internal static let emoji = "🔔"
  internal static let apiName = "modifySubscriptions+listSubscriptions+lookupSubscriptions"

  internal func run(input: NoState, context: PhaseContext) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    let subscriptionID = "mistkit-itest-\(UUID().uuidString.lowercased())"

    let created = try await context.service.createSubscription(
      .query(
        subscriptionID: subscriptionID,
        recordType: IntegrationTestData.recordType,
        firesOn: [.create, .update, .delete]
      ),
      database: context.database
    )
    if context.verbose {
      print("   ✅ Created subscription: \(created.subscriptionID)")
    }

    do {
      try await verify(subscriptionID: subscriptionID, context: context)
    } catch {
      // Best-effort cleanup before surfacing the failure.
      try? await context.service.deleteSubscription(
        id: subscriptionID, database: context.database
      )
      throw error
    }

    try await context.service.deleteSubscription(
      id: subscriptionID,
      database: context.database
    )
    if context.verbose {
      print("   ✅ Deleted subscription: \(subscriptionID)")
    }

    print("✅ Roundtrip succeeded for subscription '\(subscriptionID)'")

    return NoState()
  }

  /// Confirm the created subscription is visible via both `list` and `lookup`.
  private func verify(subscriptionID: String, context: PhaseContext) async throws {
    let all = try await context.service.listSubscriptions(database: context.database)
    guard all.contains(where: { $0.subscriptionID == subscriptionID }) else {
      throw IntegrationTestError.verificationFailed(
        "Created subscription '\(subscriptionID)' missing from listSubscriptions"
      )
    }
    if context.verbose {
      print("   ✅ Listed \(all.count) subscription(s); found ours")
    }

    let looked = try await context.service.lookupSubscriptions(
      ids: [subscriptionID],
      database: context.database
    )
    guard looked.contains(where: { $0.subscriptionID == subscriptionID }) else {
      throw IntegrationTestError.verificationFailed(
        "lookupSubscriptions did not return '\(subscriptionID)'"
      )
    }
    if context.verbose {
      print("   ✅ Looked up subscription by ID")
    }
  }
}

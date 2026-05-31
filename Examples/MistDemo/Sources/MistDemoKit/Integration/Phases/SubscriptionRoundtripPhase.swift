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

    // CloudKit dedupes query subscriptions by their query + firesOn signature,
    // not by subscriptionID, so a leftover subscription from an interrupted or
    // failed prior run (same recordType + firesOn) makes `createSubscription`
    // fail with `subscriptionLikelyDuplicate`. Sweep any stale test
    // subscriptions first so this phase is self-healing across runs.
    try await sweepStaleSubscriptions(context: context)

    let subscriptionID = "mistkit-itest-\(UUID().uuidString.lowercased())"

    let created = try await context.service.createSubscription(
      .query(
        subscriptionID: subscriptionID,
        recordType: MistDemoConfig.recordType,
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

  /// Delete leftover test subscriptions so a fresh create won't collide with
  /// CloudKit's query-signature dedup. Matches both the `mistkit-itest-` ID
  /// convention and the test's query signature (`recordType`), so the blocking
  /// subscription is cleared even if its ID differs from the current prefix.
  /// Best-effort: a failed delete shouldn't fail the phase.
  private func sweepStaleSubscriptions(context: PhaseContext) async throws {
    let existing = try await context.service.listSubscriptions(database: context.database)
    let stale = existing.filter {
      $0.subscriptionID.hasPrefix("mistkit-itest-")
        || $0.query?.recordType == MistDemoConfig.recordType
    }
    for subscription in stale {
      try? await context.service.deleteSubscription(
        id: subscription.subscriptionID,
        database: context.database
      )
      if context.verbose {
        print("   🧹 Swept stale subscription: \(subscription.subscriptionID)")
      }
    }
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

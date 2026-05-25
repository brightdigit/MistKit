//
//  NotificationRoundtripPhase.swift
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

/// End-to-end notification probe: stand up a subscription, mint a web-courier
/// token, mutate a matching record, and long-poll the courier URL for the
/// resulting push — the only fully headless way to observe a CloudKit
/// notification round trip (no device, no APNs entitlement, no signing).
///
/// - Note: This is a **probe**, not a hard assertion (issue #379). The
///   web-courier wire format isn't documented in Apple's REST reference, and
///   push delivery is asynchronous/eventual, so a non-arrival within the wait
///   window is reported as a soft warning rather than failing the suite. The
///   captured frame is logged verbatim so the wire format can be pinned down;
///   once it is, the poller can graduate into the MistKit library and this
///   phase can tighten into a real assertion.
internal struct NotificationRoundtripPhase: IntegrationPhase {
  internal typealias Input = NoState
  internal typealias Output = NoState

  internal static let title = "Trigger a subscription and await the web-courier push (probe)"
  internal static let emoji = "📨"
  internal static let apiName = "modifySubscriptions+createToken+webcourier"

  /// Bounded wait for delivery. Push is eventual; keep this generous but finite.
  private static let deliveryTimeout: Double = 45

  internal func run(input: NoState, context: PhaseContext) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    #if os(WASI)
      print("   ⏭️  Skipped: web-courier long-poll requires URLSession (unavailable on WASI).")
      return NoState()
    #else
      let suffix = UUID().uuidString.lowercased()
      let subscriptionID = "mistkit-notif-\(suffix)"

      // 1. Subscription that fires on *any* change (create/update/delete) to
      //    the shared test record type.
      _ = try await context.service.createSubscription(
        .query(
          subscriptionID: subscriptionID,
          recordType: IntegrationTestData.recordType,
          firesOn: [.create, .update, .delete]
        ),
        database: context.database
      )
      if context.verbose {
        print("   ✅ Created subscription: \(subscriptionID)")
      }

      var createdRecordName: String?
      do {
        // 2. Mint + register a courier token, then trigger a matching change.
        let courierURL = try await mintCourierToken(context: context)
        let record = try await trigger(suffix: suffix, context: context)
        createdRecordName = record.recordName

        // 3. Await our subscription's push (bounded, soft — see helper).
        await awaitPush(
          courierURL: courierURL,
          subscriptionID: subscriptionID,
          expectedRecordName: record.recordName
        )
      } catch {
        await cleanup(
          subscriptionID: subscriptionID, recordName: createdRecordName, context: context)
        throw error
      }

      await cleanup(subscriptionID: subscriptionID, recordName: createdRecordName, context: context)
      print("✅ Notification probe completed for subscription '\(subscriptionID)'")
      return NoState()
    #endif
  }

  #if !os(WASI)
    /// Mint a web-courier token and register it, so CloudKit delivers this
    /// container's subscription pushes to it. (CloudKit JS rolls both into
    /// `registerForNotifications()`.) Returns the long-poll courier URL.
    private func mintCourierToken(context: PhaseContext) async throws -> URL {
      let clientId = UUID().uuidString
      let token = try await context.service.createAPNsToken(
        environment: .development,
        clientId: clientId,
        database: context.database
      )
      try await context.service.registerAPNsToken(
        token.apnsToken,
        environment: token.environment,
        clientId: clientId,
        database: context.database
      )
      if context.verbose {
        print(
          "   ✅ Minted + registered courier token; polling \(token.webcourierURL.absoluteString)")
      }
      return token.webcourierURL
    }

    /// Create a record that matches the subscription — the change that should
    /// fire the push.
    private func trigger(suffix: String, context: PhaseContext) async throws -> RecordInfo {
      let record = try await context.service.createRecord(
        recordType: IntegrationTestData.recordType,
        recordName: "mistkit-notif-\(suffix)",
        fields: ["title": .string("notification probe \(suffix)")],
        database: context.database
      )
      if context.verbose {
        print("   ✅ Triggered with record: \(record.recordName)")
      }
      return record
    }

    /// Await *our* subscription's push within a bounded window. Other
    /// subscriptions on this record type fire too, so filter by sid. The poller
    /// is rebuilt inside the stream, so no non-Sendable state crosses the
    /// timeout boundary. Any failure here is soft — delivery is eventual and
    /// this is a probe, not a hard assertion (#379).
    private func awaitPush(
      courierURL: URL,
      subscriptionID: String,
      expectedRecordName: String
    ) async {
      do {
        let notification: CourierNotification? = try await withTimeout(
          seconds: Self.deliveryTimeout
        ) {
          for try await note in WebCourierPoller(courierURL: courierURL).notifications()
          where note.subscriptionID == subscriptionID {
            return note
          }
          return nil
        }
        guard let notification else {
          print("   ⚠️  Courier stream ended before delivering '\(subscriptionID)' (#379).")
          return
        }
        let reason = notification.reason.map(String.init(describing:)) ?? "?"
        print(
          "   ✅ Received push for '\(subscriptionID)' — "
            + "record \(notification.recordName ?? "?"), reason \(reason)"
        )
        if notification.recordName != expectedRecordName {
          print(
            "   ⚠️  Notification record '\(notification.recordName ?? "nil")' "
              + "≠ created '\(expectedRecordName)'."
          )
        }
      } catch {
        print(
          "   ⚠️  No courier push within \(formatTimeout(Self.deliveryTimeout)) "
            + "(\(error.localizedDescription)). Probe inconclusive — delivery is eventual (#379)."
        )
      }
    }
  #endif

  /// Best-effort teardown of the trigger record and subscription. Runs on both
  /// the success and failure paths; swallows its own errors so it never masks
  /// the original outcome.
  private func cleanup(
    subscriptionID: String,
    recordName: String?,
    context: PhaseContext
  ) async {
    if let recordName {
      try? await context.service.deleteRecord(
        recordType: IntegrationTestData.recordType,
        recordName: recordName,
        database: context.database
      )
    }
    try? await context.service.deleteSubscription(
      id: subscriptionID,
      database: context.database
    )
  }
}

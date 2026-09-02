//
//  CloudKitServiceTests.Subscriptions+LikelyDuplicateCases.swift
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

internal import Foundation
internal import Testing

@testable import MistKit

extension CloudKitServiceTests.Subscriptions {
  /// Tests scoped to the `INTERNAL_ERROR` / "could not find subscription
  /// we just created" marker that CloudKit returns when a create collides
  /// with an existing subscription whose `(recordType, firesOn)` already
  /// match (verified empirically via `mistdemo
  /// probe-duplicate-subscription` — uniqueness is content-based, not
  /// `subscriptionID`-based). Covers `SubscriptionOperationFailure.isLikelyDuplicate`,
  /// the convenience-wrapper throw of `.subscriptionLikelyDuplicate`, and
  /// the batch `modifySubscriptions` path keeping the raw failure intact.
  @Suite("Likely-Duplicate Cases")
  internal struct LikelyDuplicateCases {
    private static let database: Database = .public(.prefers(.serverToServer))
    private static let subID = "1CB64DC1-2423-486C-8C9F-4E064530FBEF"

    private static let internalErrorJSON = """
      {
        "subscriptions": [
          {
            "subscriptionID": "1CB64DC1-2423-486C-8C9F-4E064530FBEF",
            "reason": "could not find subscription we just created",
            "serverErrorCode": "INTERNAL_ERROR"
          }
        ]
      }
      """

    @Test("createSubscription() throws subscriptionLikelyDuplicate on the duplicate marker")
    internal func createThrowsSubscriptionLikelyDuplicate() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.Subscriptions.makeService(
        returningJSON: Self.internalErrorJSON
      )

      do {
        _ = try await service.createSubscription(
          .query(subscriptionID: Self.subID, recordType: "Note", firesOn: [.create]),
          database: Self.database
        )
        Issue.record("expected createSubscription to throw")
      } catch {
        guard case .subscriptionLikelyDuplicate(let failure) = error else {
          Issue.record("expected .subscriptionLikelyDuplicate, got \(error)")
          return
        }
        #expect(failure.identifier == Self.subID)
        #expect(failure.serverErrorCode == .internalError)
        #expect(failure.isLikelyDuplicate == true)
      }
    }

    @Test("modifySubscriptions() keeps raw failure even for likely-duplicate marker")
    internal func modifyStillReturnsRawFailureForDuplicate() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.Subscriptions.makeService(
        returningJSON: Self.internalErrorJSON
      )

      let results = try await service.modifySubscriptions(
        [.create(.query(subscriptionID: Self.subID, recordType: "Note", firesOn: [.create]))],
        database: Self.database
      )

      #expect(results.count == 1)
      guard case .failure(let failure) = try #require(results.first) else {
        Issue.record("expected a .failure result, got \(String(describing: results.first))")
        return
      }
      #expect(failure.serverErrorCode == .internalError)
      #expect(failure.isLikelyDuplicate == true)
      #expect(failure.reason == "could not find subscription we just created")
    }

    @Test("SubscriptionOperationFailure.isLikelyDuplicate matches only the exact marker")
    internal func isLikelyDuplicateMatchesExactly() {
      let exact = SubscriptionOperationFailure(
        identifier: "x",
        serverErrorCode: .internalError,
        reason: "could not find subscription we just created"
      )
      #expect(exact.isLikelyDuplicate == true)

      let wrongCode = SubscriptionOperationFailure(
        identifier: "x",
        serverErrorCode: .conflict,
        reason: "could not find subscription we just created"
      )
      #expect(wrongCode.isLikelyDuplicate == false)

      let wrongReason = SubscriptionOperationFailure(
        identifier: "x",
        serverErrorCode: .internalError,
        reason: "transient backend failure"
      )
      #expect(wrongReason.isLikelyDuplicate == false)

      let containsButNotEqual = SubscriptionOperationFailure(
        identifier: "x",
        serverErrorCode: .internalError,
        reason: "Internal: could not find subscription we just created (post-write)"
      )
      #expect(containsButNotEqual.isLikelyDuplicate == false)

      let nilReason = SubscriptionOperationFailure(
        identifier: "x",
        serverErrorCode: .internalError,
        reason: nil
      )
      #expect(nilReason.isLikelyDuplicate == false)
    }
  }
}

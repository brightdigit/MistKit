//
//  CloudKitServiceTests.Subscriptions+FailureCases.swift
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
  @Suite("Failure Cases")
  internal struct FailureCases {
    private static let database: Database = .public(.prefers(.serverToServer))
    private static let subID = "1CB64DC1-2423-486C-8C9F-4E064530FBEF"

    /// CloudKit returns a per-subscription failure inline in a 200 body. The
    /// real-world case (#379): a create that comes back as `INTERNAL_ERROR` /
    /// "could not find subscription we just created". Previously MistKit
    /// dropped the typeless entry and returned an empty array; now the failure
    /// is surfaced as a ``SubscriptionResult/failure(_:)``.
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

    /// A non-duplicate `INTERNAL_ERROR` — same code as ``internalErrorJSON``
    /// but a different `reason`, so `isLikelyDuplicate` returns `false` and
    /// the convenience wrapper falls through to the generic
    /// `subscriptionOperationFailed` path. Lets us cover that path
    /// separately from the new `subscriptionLikelyDuplicate` path.
    private static let nonDuplicateInternalErrorJSON = """
      {
        "subscriptions": [
          {
            "subscriptionID": "1CB64DC1-2423-486C-8C9F-4E064530FBEF",
            "reason": "transient backend failure",
            "serverErrorCode": "INTERNAL_ERROR"
          }
        ]
      }
      """

    private static func noteCreate(_ id: String) -> SubscriptionOperation {
      .create(.query(subscriptionID: id, recordType: "Note", firesOn: [.create]))
    }

    @Test("modifySubscriptions() surfaces a per-subscription failure")
    internal func modifySurfacesFailure() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.Subscriptions.makeService(
        returningJSON: Self.internalErrorJSON
      )

      let results = try await service.modifySubscriptions(
        [Self.noteCreate(Self.subID)],
        database: Self.database
      )

      #expect(results.count == 1)
      guard case .failure(let failure) = try #require(results.first) else {
        Issue.record("expected a .failure result, got \(String(describing: results.first))")
        return
      }
      #expect(failure.identifier == Self.subID)
      #expect(failure.serverErrorCode == .internalError)
      #expect(failure.reason == "could not find subscription we just created")
    }

    @Test("createSubscription() throws subscriptionOperationFailed on a non-duplicate failure")
    internal func createThrowsOnFailure() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.Subscriptions.makeService(
        returningJSON: Self.nonDuplicateInternalErrorJSON
      )

      do {
        _ = try await service.createSubscription(
          .query(subscriptionID: Self.subID, recordType: "Note", firesOn: [.create]),
          database: Self.database
        )
        Issue.record("expected createSubscription to throw")
      } catch {
        guard case .subscriptionOperationFailed(let failure) = error else {
          Issue.record("expected .subscriptionOperationFailed, got \(error)")
          return
        }
        #expect(failure.serverErrorCode == .internalError)
        #expect(failure.identifier == Self.subID)
        #expect(failure.isLikelyDuplicate == false)
      }
    }

    @Test("modifySubscriptions() returns mixed success and failure results")
    internal func modifyReturnsMixed() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let json = """
        {
          "subscriptions": [
            { "subscriptionID": "bad", "serverErrorCode": "INTERNAL_ERROR" },
            {
              "subscriptionID": "good",
              "subscriptionType": "query",
              "query": { "recordType": "Article" },
              "firesOn": ["create"]
            }
          ]
        }
        """
      let service = try CloudKitServiceTests.Subscriptions.makeService(returningJSON: json)

      let results = try await service.modifySubscriptions(
        [Self.noteCreate("bad"), Self.noteCreate("good")],
        database: Self.database
      )

      #expect(results.count == 2)
      guard case .failure(let failure) = results[0] else {
        Issue.record("expected results[0] to be .failure")
        return
      }
      #expect(failure.identifier == "bad")
      guard case .success(let subscription) = results[1] else {
        Issue.record("expected results[1] to be .success")
        return
      }
      #expect(subscription.subscriptionID == "good")
    }
  }
}

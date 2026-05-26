//
//  MockBackend.swift
//  MistDemoTests
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

#if canImport(Hummingbird)
  internal import Foundation
  internal import MistKit

  @testable import MistDemoKit

  /// In-memory `WebBackend` for routing-level tests. Records the last
  /// call to each operation and returns deterministic stub records.
  ///
  /// The `WebBackend` conformance is split across extension files —
  /// `MockBackend+RecordOperations` (records/zones) and
  /// `MockBackend+ServiceOperations` (subscriptions/tokens/assets) — so the
  /// recorded-call properties below are `internal` (rather than
  /// `private(set)`) to let those extensions record into them.
  internal final actor MockBackend: WebBackend {
    internal var lastQuery: QueryCall?
    internal var lastCreate: CreateCall?
    internal var lastUpdate: UpdateCall?
    internal var lastDelete: DeleteCall?
    internal var lastLookupRecords: LookupRecordsCall?
    internal var lastRecordChanges: RecordChangesCall?
    internal var lastModifyZones: ModifyZonesCall?
    internal var lastListZones: ListZonesCall?
    internal var lastLookupZones: LookupZonesCall?
    internal var lastZoneChanges: ZoneChangesCall?
    internal var didFetchCaller = false
    internal var lastDiscoverUsers: DiscoverUsersCall?
    internal var lastLookupUsersByEmail: LookupUsersByEmailCall?
    internal var lastLookupUsersByRecordName: LookupUsersByRecordNameCall?
    internal var didListSubscriptions = false
    internal var lastLookupSubscriptions: LookupSubscriptionsCall?
    internal var lastModifySubscriptions: ModifySubscriptionsCall?
    internal var lastCreateToken: CreateTokenCall?
    internal var lastRegisterToken: RegisterTokenCall?
    internal var lastRereferenceAsset: RereferenceAssetCall?
    internal var lastUploadAsset: UploadAssetCall?
    private var pendingError: String?

    /// Stub subscriptions (tests can seed); defaults to one query subscription.
    internal var stubSubscriptions: [SubscriptionInfo] = [
      .query(subscriptionID: "stub-sub", recordType: "Note", firesOn: [.create])
    ]

    internal func failNext(message: String) {
      pendingError = message
    }

    /// Throw the seeded error (if any) once, then clear it. Called at the top
    /// of every conformance method in the operation extensions.
    internal func consumePendingError() throws {
      if let message = pendingError {
        pendingError = nil
        struct StubError: LocalizedError {
          let errorDescription: String?
        }
        throw StubError(errorDescription: message)
      }
    }
  }
#endif

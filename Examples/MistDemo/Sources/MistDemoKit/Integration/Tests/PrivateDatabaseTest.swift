//
//  PrivateDatabaseTest.swift
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

internal struct PrivateDatabaseTest: PhasedIntegrationTest {
  internal let name = "Private Database"
  internal let database: MistKit.Database = .private

  // User-identity phases (`FetchCallerPhase`, `DiscoverUserIdentitiesPhase`,
  // `users/lookup/*`) stay on the public pipeline: CloudKit rejects those
  // endpoints on private with "endpoint not applicable". Share create uses the
  // private sharer service; resolve/accept are public-scoped calls run from
  // the sharee service (`ShareCreateAndAcceptPhase`) when
  // CLOUDKIT_SHAREE_WEB_AUTH_TOKEN + CLOUDKIT_SHAREE_EMAIL are set.
  internal let phases: [any IntegrationPhase] = [
    ListZonesPhase(),
    ModifyZonesPhase(),
    LookupZonePhase(),
    ZoneRoundtripPhase(),
    FetchZoneChangesPhase(),
    FetchAllZoneChangesPhase(),
    FetchRecordZoneChangesPhase(),
    UploadAssetPhase(),
    CreateRecordsPhase(),
    RereferenceAssetPhase(),
    QueryRecordsPhase(),
    LookupRecordsPhase(),
    InitialSyncPhase(),
    ModifyRecordsPhase(),
    IncrementalSyncPhase(),
    QueryRequestOptionsPhase(),
    CustomZoneQueryPhase(),
    ModifyRequestOptionsPhase(),
    ChangesRequestOptionsPhase(),
    FinalVerificationPhase(),
    SubscriptionRoundtripPhase(),
    TokenRoundtripPhase(),
    NotificationRoundtripPhase(),
    ShareCreateAndAcceptPhase(),
    CleanupPhase(),
  ]
}

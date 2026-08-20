//
//  MockBackend+Calls.swift
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

  extension MockBackend {
    /// Captured arguments from the most recent `webQuery` call.
    internal struct QueryCall: Sendable {
      internal let recordType: String
      internal let limit: Int?
      internal let sortBy: [WebRequests.QuerySortField]?
      internal let zoneName: String?
      internal let zoneOwner: String?
      internal let database: MistKit.Database
    }

    /// Captured arguments from the most recent `webCreate` call.
    internal struct CreateCall: Sendable {
      internal let recordType: String
      internal let recordName: String?
      internal let fields: [String: String]
      internal let database: MistKit.Database
    }

    /// Captured arguments from the most recent `webUpdate` call.
    internal struct UpdateCall: Sendable {
      internal let recordType: String
      internal let recordName: String
      internal let fields: [String: String]
      internal let recordChangeTag: String?
      internal let database: MistKit.Database
    }

    /// Captured arguments from the most recent `webDelete` call.
    internal struct DeleteCall: Sendable {
      internal let recordType: String
      internal let recordName: String
      internal let recordChangeTag: String?
      internal let database: MistKit.Database
    }

    /// Captured arguments from the most recent `webLookupRecords` call.
    internal struct LookupRecordsCall: Sendable {
      internal let recordNames: [String]
      internal let database: MistKit.Database
    }

    /// Captured arguments from the most recent `webRecordChanges` call.
    internal struct RecordChangesCall: Sendable {
      internal let zoneName: String?
      internal let syncToken: String?
      internal let database: MistKit.Database
    }

    /// Captured arguments from the most recent `webModifyZones` call.
    internal struct ModifyZonesCall: Sendable {
      internal let create: [String]
      internal let delete: [String]
      internal let database: MistKit.Database
    }

    /// Captured arguments from the most recent `webListZones` call.
    internal struct ListZonesCall: Sendable {
      internal let database: MistKit.Database
    }

    /// Captured arguments from the most recent `webLookupZones` call.
    internal struct LookupZonesCall: Sendable {
      internal let zoneNames: [String]
      internal let database: MistKit.Database
    }

    /// Captured arguments from the most recent `webZoneChanges` call.
    internal struct ZoneChangesCall: Sendable {
      internal let syncToken: String?
      internal let database: MistKit.Database
    }

    /// Captured arguments from the most recent `webDiscoverUsers` call.
    internal struct DiscoverUsersCall: Sendable {
      internal let emails: [String]
      internal let phoneNumbers: [String]
      internal let userRecordNames: [String]
    }

    /// Captured arguments from the most recent `webLookupSubscriptions` call.
    internal struct LookupSubscriptionsCall: Sendable {
      internal let ids: [String]
      internal let database: MistKit.Database
    }

    /// Captured arguments from the most recent `webModifySubscriptions` call.
    internal struct ModifySubscriptionsCall: Sendable {
      internal let operations: [SubscriptionOperation]
      internal let database: MistKit.Database
    }

    /// Captured arguments from the most recent `webCreateToken` call.
    internal struct CreateTokenCall: Sendable {
      internal let environment: APNsEnvironment
      internal let clientId: String?
      internal let database: MistKit.Database
    }

    /// Captured arguments from the most recent `webRegisterToken` call.
    internal struct RegisterTokenCall: Sendable {
      internal let apnsToken: String
      internal let environment: APNsEnvironment
      internal let clientId: String?
      internal let database: MistKit.Database
    }

    /// Captured arguments from the most recent `webRereferenceAsset` call.
    internal struct RereferenceAssetCall: Sendable {
      internal let sourceRecordName: String
      internal let assetField: String
      internal let targetRecordName: String
      internal let targetAssetField: String?
      internal let database: MistKit.Database
    }

    /// Captured arguments from the most recent `webUploadAsset` call.
    internal struct UploadAssetCall: Sendable {
      internal let data: Data
      internal let recordType: String
      internal let fieldName: String
      internal let recordName: String?
      internal let database: MistKit.Database
    }

    /// Captured arguments from the most recent `webResolveShares` /
    /// `webAcceptShares` call.
    internal struct ResolveOrAcceptSharesCall: Sendable {
      internal let shortGUIDs: [String]
      internal let fetchRootRecord: Bool?
      internal let fields: [String]?
    }
  }
#endif

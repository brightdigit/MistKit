//
//  WebResponse.swift
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

/// Response payloads for the web command's CRUD endpoints.
internal enum WebResponse {
  /// Body returned by record-shaped routes (query / create / update).
  internal struct Records: Encodable {
    internal let records: [RecordInfo]
  }

  /// Body returned by `delete` (no record payload).
  internal struct Delete: Encodable {
    internal let recordName: String
    internal let deleted: Bool
  }

  /// Body returned by `records/changes`: the changed records plus the
  /// continuation `syncToken` and `moreComing` flag from
  /// `RecordChangesResult`.
  internal struct RecordChanges: Encodable {
    internal let records: [RecordInfo]
    internal let syncToken: String?
    internal let moreComing: Bool

    internal init(from result: RecordChangesResult) {
      self.records = result.records
      self.syncToken = result.syncToken
      self.moreComing = result.moreComing
    }
  }

  /// Body returned by `zones/changes` (backed by `changes/database`, the
  /// current replacement for the deprecated `zones/changes` operation): the
  /// changed zones plus any per-zone failures and the continuation
  /// `syncToken` / `moreComing` flag from `DatabaseChangesResult`.
  internal struct ZoneChanges: Encodable {
    internal let zones: [ZoneInfo]
    internal let failures: [ZoneOperationFailure]
    internal let syncToken: String?
    internal let moreComing: Bool

    internal init(from result: DatabaseChangesResult) {
      self.zones = result.changedZones
      self.failures = result.failures
      self.syncToken = result.syncToken
      self.moreComing = result.moreComing
    }
  }

  /// Body returned by `POST /api/changes/zone`: per-zone record changes,
  /// mirroring `RecordZoneChangesResult`. `changes/zone` paginates
  /// independently per zone, so there is no top-level `syncToken` — each
  /// zone entry carries its own.
  internal struct ZoneRecordChanges: Encodable {
    /// One requested zone's outcome: its record changes plus its own
    /// continuation `syncToken` and `moreComing` flag.
    internal struct Zone: Encodable {
      internal let zone: ZoneInfo
      internal let records: [RecordInfo]
      internal let syncToken: String?
      internal let moreComing: Bool

      internal init(from changes: MistKit.ZoneRecordChanges) {
        self.zone = changes.zone
        self.records = changes.records
        self.syncToken = changes.syncToken
        self.moreComing = changes.moreComing
      }
    }

    internal let zones: [Zone]
    internal let failures: [ZoneOperationFailure]

    internal init(from result: RecordZoneChangesResult) {
      self.zones = result.changes.map(Zone.init(from:))
      self.failures = result.failures
    }
  }

  /// Body returned by `users/caller`: the calling user's `UserInfo`.
  internal struct Caller: Encodable {
    internal let user: UserInfo
  }

  /// Body returned by the user-identity discover route (`users/discover`).
  internal struct Users: Encodable {
    internal let users: [UserIdentity]
  }

  /// Body returned by zone routes (`zones/modify`). `ZoneInfo` encodes to
  /// `{ zoneName, ownerRecordName, capabilities }`, which the browser's
  /// zone table reads directly.
  internal struct Zones: Encodable {
    internal let zones: [ZoneInfo]
  }

  /// Body returned by subscription routes (`list` / `lookup` / `modify`).
  /// `SubscriptionInfo` encodes to `{ subscriptionID, subscriptionType, query,
  /// zoneID, firesOn }`, matching the browser's subscription table and the
  /// CloudKit JS `{ subscriptions: [...] }` shape.
  internal struct Subscriptions: Encodable {
    internal let subscriptions: [SubscriptionInfo]
  }

  /// Body returned by `tokens/create`. Echoes CloudKit's wire field names so
  /// the demo panel shows the canonical shape per Apple's `CreateTokens.html`
  /// REST reference: `apnsEnvironment`, `apnsToken`, `webcourierURL`.
  internal struct Token: Encodable {
    internal let apnsEnvironment: APNsEnvironment
    internal let apnsToken: String
    internal let webcourierURL: URL

    internal init(from result: APNsTokenResult) {
      self.apnsEnvironment = result.environment
      self.apnsToken = result.apnsToken
      self.webcourierURL = result.webcourierURL
    }
  }

  /// Body returned by `tokens/register` (no payload from CloudKit).
  internal struct TokenRegistration: Encodable {
    internal let registered: Bool
  }

  /// Body returned by `records/resolve` and `records/accept`. `ShareRecordInfo`
  /// already encodes to the wire shape the browser panel wants, so this is a
  /// thin wrapper.
  internal struct Shares: Encodable {
    internal let results: [ShareRecordInfo]
  }

  /// Body returned for any handled CloudKit/MistKit error so the UI can
  /// surface the message without parsing transport-level failures.
  internal struct Error: Encodable {
    internal let message: String
  }
}

//
//  CloudKitStore+Zones.swift
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

#if canImport(CloudKit)
  internal import CloudKit
  internal import Foundation
  internal import MistDemoKit

  /// Snapshot returned by `CKFetchDatabaseChangesOperation` so the UI can
  /// show what changed since the last sync token.
  internal struct DatabaseChangesSnapshot: Sendable {
    internal let changedZoneIDs: [CKRecordZone.ID]
    internal let deletedZoneIDs: [CKRecordZone.ID]
    internal let serverChangeToken: CKServerChangeToken?
    internal let moreComing: Bool
  }

  extension CloudKitStore {
    /// Create a new custom record zone in the selected database. Public
    /// databases reject this — `CKModifyRecordZonesOperation` returns an
    /// error which we surface to the UI.
    internal func createZone(named name: String) async throws -> ZoneRow {
      let zone = CKRecordZone(zoneName: name)
      let saved = try await database.save(zone)
      return ZoneRow(saved)
    }

    /// Delete a custom record zone by name in the selected database.
    internal func deleteZone(named name: String) async throws {
      _ = try await database.deleteRecordZone(
        withID: CKRecordZone.ID(
          zoneName: name, ownerName: CKCurrentUserDefaultName
        )
      )
    }

    /// Fetch database-scope changes since `previousToken`. Returns the
    /// changed/deleted zone IDs plus the new sync token. Pass the returned
    /// token on the next call to receive a delta.
    internal func fetchDatabaseChanges(
      since previousToken: CKServerChangeToken? = nil
    ) async throws -> DatabaseChangesSnapshot {
      try await withCheckedThrowingContinuation { continuation in
        let operation = CKFetchDatabaseChangesOperation(
          previousServerChangeToken: previousToken
        )

        var changed: [CKRecordZone.ID] = []
        var deleted: [CKRecordZone.ID] = []

        operation.recordZoneWithIDWasDeletedBlock = { deleted.append($0) }
        operation.recordZoneWithIDChangedBlock = { changed.append($0) }
        operation.fetchDatabaseChangesResultBlock = { result in
          switch result {
          case .failure(let error):
            continuation.resume(throwing: error)
          case .success(let payload):
            continuation.resume(
              returning: DatabaseChangesSnapshot(
                changedZoneIDs: changed,
                deletedZoneIDs: deleted,
                serverChangeToken: payload.serverChangeToken,
                moreComing: payload.moreComing
              )
            )
          }
        }

        database.add(operation)
      }
    }
  }
#endif

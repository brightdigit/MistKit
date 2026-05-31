//
//  CloudKitStore+Records.swift
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

  extension CloudKitStore {
    /// Look up records by name. Maps to `records/lookup` in the REST
    /// surface; uses `database.record(for:)` per ID.
    internal func lookupRecords(names: [String]) async throws -> [Note] {
      var notes: [Note] = []
      for name in names {
        let recordID = CKRecord.ID(recordName: name)
        let record = try await database.record(for: recordID)
        if let note = Note(record) {
          notes.append(note)
        }
      }
      return notes
    }

    /// Fetch record-level deltas for the given zone since `previousToken`.
    /// Returns the changed and deleted record names plus the new sync
    /// token. Pass that token back on the next call for an incremental
    /// fetch. Maps to `records/changes` in the REST surface.
    internal func fetchRecordZoneChanges(
      zoneID: CKRecordZone.ID,
      since previousToken: CKServerChangeToken? = nil
    ) async throws -> RecordZoneChangesSnapshot {
      try await withCheckedThrowingContinuation { continuation in
        let configuration =
          CKFetchRecordZoneChangesOperation
          .ZoneConfiguration(previousServerChangeToken: previousToken)
        let operation = CKFetchRecordZoneChangesOperation(
          recordZoneIDs: [zoneID],
          configurationsByRecordZoneID: [zoneID: configuration]
        )

        var changed: [String] = []
        var deleted: [String] = []
        var resolvedToken: CKServerChangeToken?
        var moreComing = false

        operation.recordWasChangedBlock = { recordID, _ in
          changed.append(recordID.recordName)
        }
        operation.recordWithIDWasDeletedBlock = { recordID, _ in
          deleted.append(recordID.recordName)
        }
        operation.recordZoneFetchResultBlock = { _, result in
          if case .success(let payload) = result {
            resolvedToken = payload.serverChangeToken
            moreComing = payload.moreComing
          }
        }
        operation.fetchRecordZoneChangesResultBlock = { result in
          switch result {
          case .failure(let error):
            continuation.resume(throwing: error)
          case .success:
            continuation.resume(
              returning: RecordZoneChangesSnapshot(
                changedRecordNames: changed,
                deletedRecordNames: deleted,
                serverChangeToken: resolvedToken,
                moreComing: moreComing
              )
            )
          }
        }

        database.add(operation)
      }
    }

    /// Resolve a record reference. Accepts either a CloudKit record name
    /// (routed through `database.record(for:)`) or a share URL (routed
    /// through `CKContainer.share(metadataFor:)`). Maps to `records/resolve`
    /// in the REST surface as a composed call.
    internal func resolveReference(input: String) async throws -> ResolveResult {
      if let url = URL(string: input), url.scheme?.hasPrefix("http") == true {
        let container = CKContainer(identifier: containerIdentifier)
        let metadata = try await container.shareMetadata(for: url)
        return ResolveResult(
          source: .shareURL,
          recordName: metadata.rootRecordID.recordName,
          recordType: metadata.rootRecord?.recordType,
          shareTitle: metadata.share[CKShare.SystemFieldKey.title] as? String
        )
      }
      let record = try await database.record(
        for: CKRecord.ID(recordName: input)
      )
      return ResolveResult(
        source: .recordName,
        recordName: record.recordID.recordName,
        recordType: record.recordType,
        shareTitle: nil
      )
    }
  }
#endif

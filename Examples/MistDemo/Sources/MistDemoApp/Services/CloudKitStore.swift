//
//  CloudKitStore.swift
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

#if canImport(CloudKit) && !os(tvOS) && !os(watchOS)
  import CloudKit
  import Foundation
  import MistDemoKit
  public import Observation

  /// Observable source of truth for the MistDemo app's CloudKit state.
  ///
  /// Wraps `CKContainer`/`CKDatabase` directly. MistKit's REST surface is
  /// reserved for server/Linux/WASI/Windows contexts where the CloudKit
  /// framework isn't available.
  @Observable
  @MainActor
  public final class CloudKitStore {
    /// The shared demo container identifier — must match `MistDemoConfig.containerIdentifier`.
    public static let demoContainerIdentifier = "iCloud.com.brightdigit.MistDemo"

    internal var accountStatus: CKAccountStatus = .couldNotDetermine
    internal var lastError: String?
    internal var databaseScope: CKDatabase.Scope = .private

    /// The signed-in iCloud user's record name. Mirrors `currentUserRecordName`
    /// in the web demo and is used to flag the "You" badge on notes the
    /// current user created.
    internal var currentUserRecordName: String?

    internal let containerIdentifier: String
    @ObservationIgnored private let container: CKContainer

    /// The CloudKit database for the current `databaseScope`.
    internal var database: CKDatabase { container.database(with: databaseScope) }

    /// Creates a new service for the given CloudKit container.
    /// - Parameter containerIdentifier: The CloudKit container identifier.
    public init(containerIdentifier: String) {
      self.containerIdentifier = containerIdentifier
      self.container = CKContainer(identifier: containerIdentifier)
    }

    /// Apply the editable fields onto a CKRecord. CloudKit's system metadata
    /// (`creationDate`, `modificationDate`) is refreshed by the server on save,
    /// so no manual timestamping is needed.
    private static func apply(
      title: String, index: Int64, imageURL: URL?, to record: CKRecord
    ) {
      record[Note.Fields.title] = title as NSString
      record[Note.Fields.index] = NSNumber(value: index)
      if let imageURL {
        record[Note.Fields.image] = CKAsset(fileURL: imageURL)
      }
    }

    internal func refreshAccountStatus() async {
      do {
        let status = try await container.accountStatus()
        self.accountStatus = status
      } catch {
        self.accountStatus = .couldNotDetermine
        self.lastError = error.localizedDescription
      }
      if accountStatus == .available {
        do {
          let recordID = try await container.userRecordID()
          self.currentUserRecordName = recordID.recordName
        } catch {
          self.currentUserRecordName = nil
          self.lastError = error.localizedDescription
        }
      } else {
        self.currentUserRecordName = nil
      }
    }

    /// List all record zones in the selected database (parity with `mistdemo lookup-zones`).
    internal func loadZones() async throws -> [ZoneRow] {
      let zones = try await database.allRecordZones()
      return zones.map(ZoneRow.init).sorted { $0.zoneName < $1.zoneName }
    }

    /// Query `Note` records from the selected database, newest first —
    /// primary sort on creation date desc, modification date desc as the
    /// tiebreaker. Matches the web demo's default sort.
    /// Note's schema is defined in `schema.ckdb` (`___createTime` and
    /// `___modTime` are both `SORTABLE`).
    internal func queryNotes(limit: Int = 50) async throws -> [Note] {
      let predicate = NSPredicate(value: true)
      let query = CKQuery(recordType: Note.recordType, predicate: predicate)
      query.sortDescriptors = [
        NSSortDescriptor(key: "creationDate", ascending: false),
        NSSortDescriptor(key: "modificationDate", ascending: false),
      ]

      let (matchResults, _) = try await database.records(
        matching: query,
        inZoneWith: nil,
        desiredKeys: nil,
        resultsLimit: limit
      )

      var notes: [Note] = []
      var failedCount = 0
      var firstFailure: (any Error)?
      for (_, recordResult) in matchResults {
        switch recordResult {
        case .success(let record):
          if let note = Note(record) {
            notes.append(note)
          } else {
            failedCount += 1
          }
        case .failure(let error):
          failedCount += 1
          if firstFailure == nil { firstFailure = error }
        }
      }

      if failedCount > 0 {
        let detail = firstFailure.map { ": \($0.localizedDescription)" } ?? ""
        self.lastError = "Skipped \(failedCount) record(s)\(detail)"
      }

      return notes
    }

    // MARK: - Write operations (parity with `mistdemo create / update / delete`)

    /// Create a new Note in the selected database.
    internal func createNote(title: String, index: Int64, imageURL: URL?) async throws -> Note {
      let record = CKRecord(recordType: Note.recordType)
      Self.apply(title: title, index: index, imageURL: imageURL, to: record)
      let saved = try await database.save(record)
      guard let note = Note(saved) else {
        throw CloudKitStoreError.unexpectedSaveResult
      }
      return note
    }

    /// Update an existing Note: fetch the underlying record by ID, apply the
    /// new field values, and save. The fetch picks up the current change tag
    /// so the save is rejected (rather than blindly clobbering) if the record
    /// has been modified since the caller read it.
    internal func updateNote(
      _ existing: Note, title: String, index: Int64, imageURL: URL?
    ) async throws -> Note {
      let recordID = CKRecord.ID(recordName: existing.id)
      let record = try await database.record(for: recordID)
      Self.apply(title: title, index: index, imageURL: imageURL, to: record)
      let saved = try await database.save(record)
      guard let note = Note(saved) else {
        throw CloudKitStoreError.unexpectedSaveResult
      }
      return note
    }

    /// Delete a Note by record ID.
    internal func deleteNote(_ note: Note) async throws {
      _ = try await database.deleteRecord(
        withID: CKRecord.ID(recordName: note.id)
      )
    }

    /// Capture a web-auth token via `CKFetchWebAuthTokenOperation` for the
    /// given CloudKit API token. Always runs against the private database —
    /// running the operation against the public database fails or returns
    /// an unattributed token, regardless of the user's scope selection.
    internal func fetchWebAuthToken(apiToken: String) async throws -> String {
      try await container.privateCloudDatabase.fetchWebAuthToken(apiToken: apiToken)
    }
  }
#endif

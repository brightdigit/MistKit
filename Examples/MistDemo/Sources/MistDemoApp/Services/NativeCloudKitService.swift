//
//  NativeCloudKitService.swift
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
  public import Combine
  import Foundation

  /// Thin wrapper around Apple's CloudKit framework that mirrors the read-side
  /// operations the MistKit-driven MistDemo CLI exposes. The two demos hit the
  /// same CloudKit container, so a presentation can flip between them and show
  /// identical data accessed through different stacks.
  @MainActor
  public final class NativeCloudKitService: ObservableObject {
    /// The shared demo container identifier — must match `MistDemoConfig.containerIdentifier`.
    public static let demoContainerIdentifier = "iCloud.com.brightdigit.MistDemo"

    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var lastError: String?

    let containerIdentifier: String
    private let container: CKContainer

    public init(containerIdentifier: String) {
      self.containerIdentifier = containerIdentifier
      self.container = CKContainer(identifier: containerIdentifier)
    }

    /// Convenience: which database we want to demo against. The MistDemo CLI
    /// defaults to `.private`, so mirror that here.
    var database: CKDatabase { container.privateCloudDatabase }

    func refreshAccountStatus() async {
      do {
        let status = try await container.accountStatus()
        self.accountStatus = status
      } catch {
        self.accountStatus = .couldNotDetermine
        self.lastError = error.localizedDescription
      }
    }

    /// List all record zones in the private database (parity with `mistdemo lookup-zones`).
    func loadZones() async throws -> [ZoneRow] {
      let zones = try await database.allRecordZones()
      return zones.map(ZoneRow.init).sorted { $0.zoneName < $1.zoneName }
    }

    /// Query `Note` records from the demo container's private database, sorted
    /// by `index` (parity with `mistdemo query --record-type Note --sort index`).
    /// Note's schema is defined in `schema.ckdb`.
    func queryNotes(limit: Int = 50) async throws -> [Note] {
      let predicate = NSPredicate(value: true)
      let query = CKQuery(recordType: Note.recordType, predicate: predicate)
      query.sortDescriptors = [NSSortDescriptor(key: Note.Fields.index, ascending: true)]

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

    /// Create a new Note in the private database.
    func createNote(title: String, index: Int64, imageURL: URL?) async throws -> Note {
      let record = CKRecord(recordType: Note.recordType)
      Self.apply(title: title, index: index, imageURL: imageURL, to: record)
      record[Note.Fields.createdAt] = Date() as NSDate
      let saved = try await database.save(record)
      guard let note = Note(saved) else {
        throw NativeCloudKitError.unexpectedSaveResult
      }
      return note
    }

    /// Update an existing Note. Fetches the current record (so the change tag
    /// is fresh), mutates the fields, and saves.
    func updateNote(_ existing: Note, title: String, index: Int64, imageURL: URL?) async throws
      -> Note
    {
      let recordID = CKRecord.ID(recordName: existing.id)
      let record = try await database.record(for: recordID)
      Self.apply(title: title, index: index, imageURL: imageURL, to: record)
      let saved = try await database.save(record)
      guard let note = Note(saved) else {
        throw NativeCloudKitError.unexpectedSaveResult
      }
      return note
    }

    /// Delete a Note by record name.
    func deleteNote(_ note: Note) async throws {
      let recordID = CKRecord.ID(recordName: note.id)
      _ = try await database.deleteRecord(withID: recordID)
    }

    // MARK: - Web auth token (parity with `mistdemo auth-token`)

    /// Fetch a CloudKit web auth token (the `158__...` value that MistKit /
    /// the MistDemo CLI consume). Demonstrates that a native app and a
    /// REST-based MistKit consumer can share the same auth surface.
    ///
    /// `apiToken` is the public CloudKit API token from CloudKit Dashboard,
    /// not the user's iCloud password. It must match the configured container.
    func fetchWebAuthToken(apiToken: String) async throws -> String {
      try await withCheckedThrowingContinuation { continuation in
        let operation = CKFetchWebAuthTokenOperation(apiToken: apiToken)
        operation.qualityOfService = .userInitiated
        operation.fetchWebAuthTokenCompletionBlock = { token, error in
          if let token {
            continuation.resume(returning: token)
          } else {
            continuation.resume(throwing: error ?? NativeCloudKitError.webAuthTokenUnavailable)
          }
        }
        // CKFetchWebAuthTokenOperation is a CKDatabaseOperation; running
        // it against the private database picks up the demo container.
        database.add(operation)
      }
    }

    /// Apply the editable fields onto a CKRecord. Always refreshes `modified`.
    private static func apply(title: String, index: Int64, imageURL: URL?, to record: CKRecord) {
      record[Note.Fields.title] = title as NSString
      record[Note.Fields.index] = NSNumber(value: index)
      if let imageURL {
        record[Note.Fields.image] = CKAsset(fileURL: imageURL)
      }
      record[Note.Fields.modified] = NSNumber(value: Int64(Date().timeIntervalSince1970 * 1_000))
    }
  }
#endif

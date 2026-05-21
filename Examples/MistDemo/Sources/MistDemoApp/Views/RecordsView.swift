//
//  RecordsView.swift
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

#if canImport(SwiftUI) && canImport(CloudKit)
  internal import CloudKit
  internal import MistDemoKit
  internal import SwiftUI

  /// View driving `records/lookup`, `records/changes`, and the composed
  /// `records/resolve` against native CloudKit. Lookup and resolve accept
  /// the same input shape (a record name) but resolve also accepts a
  /// share URL; the underlying composition is documented inline via
  /// `CompositionDisclosure`.
  internal struct RecordsView: View {
    @Environment(CloudKitStore.self) private var service
    @State private var lookupInput: String = ""
    @State private var lookupResults: [Note] = []
    @State private var lookupError: String?
    @State private var resolveInput: String = ""
    @State private var resolveResult: ResolveResult?
    @State private var resolveError: String?
    @State private var changesSnapshot: RecordZoneChangesSnapshot?
    @State private var changesError: String?
    @State private var changesToken: CKServerChangeToken?
    @State private var loading = false

    internal var body: some View {
      Form {
        lookupSection
        changesSection
        resolveSection
      }
      .formStyle(.grouped)
      .navigationTitle("Records")
    }

    private var lookupSection: some View {
      Section {
        TextField("Record name", text: $lookupInput)
          .font(.body.monospaced())
        Button("Lookup") { Task { await runLookup() } }
          .disabled(lookupInput.isEmpty || loading)
        if let lookupError {
          Text(lookupError).font(.callout).foregroundStyle(.red)
        }
        ForEach(lookupResults) { note in
          VStack(alignment: .leading, spacing: 2) {
            Text(note.title ?? "(untitled)").font(.headline)
            Text(note.id).font(.caption.monospaced())
              .foregroundStyle(.secondary)
          }
        }
      } header: {
        Text("Lookup — records/lookup")
      } footer: {
        Text("CKFetchRecordsOperation / database.record(for:)")
          .font(.caption)
      }
    }

    private var changesSection: some View {
      Section {
        Button("Fetch changes (_defaultZone)") {
          Task { await runChanges() }
        }
        .disabled(loading)
        if let changesError {
          Text(changesError).font(.callout).foregroundStyle(.red)
        }
        if let snapshot = changesSnapshot {
          LabeledContent("Changed", value: "\(snapshot.changedRecordNames.count)")
          LabeledContent("Deleted", value: "\(snapshot.deletedRecordNames.count)")
          LabeledContent("More coming", value: snapshot.moreComing ? "Yes" : "No")
        }
      } header: {
        Text("Changes — records/changes")
      } footer: {
        Text("CKFetchRecordZoneChangesOperation. Repeat calls return deltas.")
          .font(.caption)
      }
    }

    private var resolveSection: some View {
      Section {
        TextField(
          "Record name or share URL",
          text: $resolveInput
        )
        .font(.body.monospaced())
        Button("Resolve") { Task { await runResolve() } }
          .disabled(resolveInput.isEmpty || loading)
        if let resolveError {
          Text(resolveError).font(.callout).foregroundStyle(.red)
        }
        if let result = resolveResult {
          LabeledContent("Branch", value: result.source.rawValue)
          if let name = result.recordName {
            LabeledContent("Record", value: name)
          }
          if let type = result.recordType {
            LabeledContent("Type", value: type)
          }
          if let title = result.shareTitle {
            LabeledContent("Share title", value: title)
          }
        }
        CompositionDisclosure(
          restEndpoint: "records/resolve",
          steps: [
            "Record name → database.record(for: CKRecord.ID(recordName:))",
            "Share URL → container.shareMetadata(for: url)",
          ]
        )
      } header: {
        Text("Resolve — records/resolve (composed)")
      }
    }

    private func runLookup() async {
      loading = true
      lookupError = nil
      defer { loading = false }
      do {
        let names = lookupInput.split(separator: ",")
          .map { String($0).trimmingCharacters(in: .whitespaces) }
          .filter { !$0.isEmpty }
        lookupResults = try await service.lookupRecords(names: names)
      } catch {
        lookupResults = []
        lookupError = error.localizedDescription
      }
    }

    private func runChanges() async {
      loading = true
      changesError = nil
      defer { loading = false }
      do {
        let snapshot = try await service.fetchRecordZoneChanges(
          zoneID: CKRecordZone.ID(zoneName: CKRecordZone.ID.defaultZoneName),
          since: changesToken
        )
        changesSnapshot = snapshot
        changesToken = snapshot.serverChangeToken
      } catch {
        changesSnapshot = nil
        changesError = error.localizedDescription
      }
    }

    private func runResolve() async {
      loading = true
      resolveError = nil
      defer { loading = false }
      do {
        resolveResult = try await service.resolveReference(input: resolveInput)
      } catch {
        resolveResult = nil
        resolveError = error.localizedDescription
      }
    }
  }
#endif

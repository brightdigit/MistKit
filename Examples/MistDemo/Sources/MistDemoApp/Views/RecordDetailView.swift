//
//  RecordDetailView.swift
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

#if canImport(SwiftUI) && canImport(CloudKit) && !os(tvOS) && !os(watchOS)
  import SwiftUI

  struct RecordDetailView: View {
    @State var note: Note
    let onChange: () -> Void

    @EnvironmentObject private var service: NativeCloudKitService
    @Environment(\.dismiss) private var dismiss

    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var deleting = false
    @State private var actionError: String?

    var body: some View {
      Form {
        Section("Identity") {
          LabeledContent("Record Name", value: note.id)
          LabeledContent("Record Type", value: Note.recordType)
          if let recordChangeTag = note.recordChangeTag {
            LabeledContent("Change Tag", value: recordChangeTag)
          }
          if let creationDate = note.creationDate {
            LabeledContent(
              "Created", value: creationDate.formatted(date: .abbreviated, time: .standard))
          }
          if let modificationDate = note.modificationDate {
            LabeledContent(
              "Modified", value: modificationDate.formatted(date: .abbreviated, time: .standard))
          }
        }

        Section("Note Fields") {
          LabeledContent("title", value: note.title ?? "—")
          LabeledContent("index", value: note.index.map(String.init) ?? "—")
          LabeledContent(
            "createdAt",
            value: note.createdAt?.formatted(date: .abbreviated, time: .standard) ?? "—")
          LabeledContent("modified", value: note.modified.map(String.init) ?? "—")
          LabeledContent("image", value: note.imageAssetURL?.lastPathComponent ?? "—")
        }

        if let url = note.imageAssetURL {
          Section("Asset") {
            AsyncImage(url: url) { image in
              image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
              ProgressView()
            }
            .frame(maxHeight: 240)
          }
        }

        if let actionError {
          Section("Error") {
            Text(actionError).foregroundStyle(.red).font(.callout)
          }
        }
      }
      .formStyle(.grouped)
      .navigationTitle(note.title ?? note.id)
      .toolbar {
        ToolbarItem {
          Button {
            showEditSheet = true
          } label: {
            Label("Edit", systemImage: "pencil")
          }
        }
        ToolbarItem {
          Button(role: .destructive) {
            showDeleteConfirmation = true
          } label: {
            Label("Delete", systemImage: "trash")
          }
          .disabled(deleting)
        }
      }
      .sheet(isPresented: $showEditSheet) {
        NoteEditView(mode: .edit(note)) { updated in
          note = updated
          onChange()
        }
        .environmentObject(service)
      }
      .confirmationDialog(
        "Delete \(note.title ?? note.id)?",
        isPresented: $showDeleteConfirmation,
        titleVisibility: .visible
      ) {
        Button("Delete", role: .destructive) {
          Task { await delete() }
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text("This permanently removes the record from CloudKit.")
      }
    }

    private func delete() async {
      deleting = true
      actionError = nil
      defer { deleting = false }
      do {
        try await service.deleteNote(note)
        onChange()
        dismiss()
      } catch {
        actionError = error.localizedDescription
      }
    }
  }
#endif

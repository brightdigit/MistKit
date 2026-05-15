//
//  NoteEditView.swift
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
  import MistDemoKit
  import SwiftUI
  import UniformTypeIdentifiers

  /// Sheet form for creating or editing a Note. The same view backs both flows;
  /// the `mode` value drives the title and which service method is called on save.
  internal struct NoteEditView: View {
    internal enum Mode {
      case create
      case edit(Note)
    }

    internal let mode: Mode
    internal let onSaved: (Note) -> Void

    @Environment(CloudKitStore.self) private var service
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var indexText: String = "0"
    @State private var imageURL: URL?
    @State private var saving = false
    @State private var saveError: String?
    @State private var showFileImporter = false

    // Tracks the URL whose security-scoped access we currently hold so we can
    // balance the start/stop calls across the view's lifetime — picking a
    // different file, tapping Remove, or dismissing the sheet must all
    // release the previous scope.
    @State private var scopedURL: URL?

    private var navigationTitle: String {
      switch mode {
      case .create:
        return "New Note"
      case .edit:
        return "Edit Note"
      }
    }

    private var isValid: Bool {
      !title.trimmingCharacters(in: .whitespaces).isEmpty
        && Int64(indexText) != nil
    }

    internal var body: some View {
      NavigationStack {
        formContent
          .formStyle(.grouped)
          .navigationTitle(navigationTitle)
          .toolbar { toolbarContent }

          #if !os(tvOS) && !os(watchOS)
            .fileImporter(
              isPresented: $showFileImporter,
              allowedContentTypes: [.image],
              allowsMultipleSelection: false
            ) { result in
              handleFileImport(result)
            }
          #endif
      }
      .onAppear { populateInitialState() }
      .onDisappear { releaseScopedURL() }
      .frame(minWidth: 420, minHeight: 360)
    }

    @ViewBuilder private var formContent: some View {
      Form {
        Section("Note") {
          TextField("Title", text: $title)
          TextField("Index", text: $indexText)
            #if os(iOS)
              .keyboardType(.numberPad)
            #endif
        }

        imageSection

        if let saveError {
          Section("Error") {
            Text(saveError).foregroundStyle(.red).font(.callout)
          }
        }
      }
    }

    @ViewBuilder private var imageSection: some View {
      Section("Image (optional)") {
        if let imageURL {
          LabeledContent("File") {
            Text(imageURL.lastPathComponent)
              .lineLimit(1)
              .truncationMode(.middle)
          }
          Button("Remove", role: .destructive) {
            releaseScopedURL()
            self.imageURL = nil
          }
        }
        Button("Choose image…") { showFileImporter = true }
      }
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") { dismiss() }
          .disabled(saving)
      }
      ToolbarItem(placement: .confirmationAction) {
        if saving {
          ProgressView().controlSize(.small)
        } else {
          Button("Save") { Task { await save() } }
            .disabled(!isValid)
        }
      }
    }

    private func handleFileImport(_ result: Result<[URL], any Error>) {
      switch result {
      case .success(let urls):
        if let url = urls.first {
          guard url.startAccessingSecurityScopedResource() else {
            saveError =
              "Couldn't access \(url.lastPathComponent) — file permissions denied."
            return
          }
          // Release the previously-scoped URL before adopting the new one.
          releaseScopedURL()
          scopedURL = url
          imageURL = url
        }
      case .failure(let error):
        saveError = "Couldn't pick file: \(error.localizedDescription)"
      }
    }

    private func releaseScopedURL() {
      scopedURL?.stopAccessingSecurityScopedResource()
      scopedURL = nil
    }

    private func populateInitialState() {
      guard case .edit(let note) = mode else {
        return
      }
      title = note.title ?? ""
      indexText = note.index.map(String.init) ?? "0"
      imageURL = note.imageAssetURL
    }

    private func save() async {
      saving = true
      saveError = nil
      defer { saving = false }

      guard let parsedIndex = Int64(indexText) else {
        saveError = "Index must be an integer"
        return
      }
      let trimmedTitle = title.trimmingCharacters(in: .whitespaces)

      do {
        let note: Note
        switch mode {
        case .create:
          note = try await service.createNote(
            title: trimmedTitle,
            index: parsedIndex,
            imageURL: imageURL
          )
        case .edit(let existing):
          note = try await service.updateNote(
            existing,
            title: trimmedTitle,
            index: parsedIndex,
            imageURL: imageURL
          )
        }
        onSaved(note)
        dismiss()
      } catch {
        saveError = error.localizedDescription
      }
    }
  }
#endif

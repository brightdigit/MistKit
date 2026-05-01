//
//  QueryView.swift
//  MistDemoApp
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

import SwiftUI

struct QueryView: View {
    @EnvironmentObject private var service: NativeCloudKitService
    @State private var limit: Int = 50
    @State private var notes: [Note] = []
    @State private var loading = false
    @State private var loadError: String?
    @State private var selectedNote: Note?

    var body: some View {
        VStack(spacing: 0) {
            controls
                .padding()

            Divider()

            if loading {
                Spacer()
                ProgressView("Querying \(Note.recordType)…")
                Spacer()
            } else if let loadError {
                ContentUnavailableView("Query failed", systemImage: "exclamationmark.triangle", description: Text(loadError))
            } else if notes.isEmpty {
                ContentUnavailableView("No notes", systemImage: "tray", description: Text("Run a query, or create a Note via `mistdemo create` first."))
            } else {
                List(notes, selection: $selectedNote) { note in
                    NavigationLink(value: note) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(note.title ?? note.id).font(.body)
                            HStack(spacing: 12) {
                                if let index = note.index {
                                    Label("\(index)", systemImage: "number")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if let createdAt = note.createdAt {
                                    Label(createdAt.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationDestination(for: Note.self) { note in
            RecordDetailView(note: note)
        }
        .navigationTitle("Notes")
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Text("Type: \(Note.recordType)")
                .font(.body.monospaced())
                .foregroundStyle(.secondary)

            Stepper(value: $limit, in: 1...200, step: 10) {
                Text("Limit: \(limit)")
            }
            .frame(maxWidth: 200)

            Button("Run Query") { Task { await runQuery() } }
                .buttonStyle(.borderedProminent)
        }
    }

    private func runQuery() async {
        loading = true
        loadError = nil
        defer { loading = false }
        do {
            notes = try await service.queryNotes(limit: limit)
        } catch {
            loadError = error.localizedDescription
        }
    }
}

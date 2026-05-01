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
    @State private var recordType: String = "Note"
    @State private var limit: Int = 50
    @State private var records: [RecordRow] = []
    @State private var loading = false
    @State private var loadError: String?
    @State private var selectedRecord: RecordRow?

    var body: some View {
        VStack(spacing: 0) {
            controls
                .padding()

            Divider()

            if loading {
                Spacer()
                ProgressView("Querying…")
                Spacer()
            } else if let loadError {
                ContentUnavailableView("Query failed", systemImage: "exclamationmark.triangle", description: Text(loadError))
            } else if records.isEmpty {
                ContentUnavailableView("No results", systemImage: "tray", description: Text("Run a query to see records."))
            } else {
                List(records, selection: $selectedRecord) { record in
                    NavigationLink(value: record) {
                        VStack(alignment: .leading) {
                            Text(record.recordName).font(.body)
                            Text(record.recordType).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationDestination(for: RecordRow.self) { row in
            RecordDetailView(record: row)
        }
        .navigationTitle("Query")
    }

    private var controls: some View {
        HStack(spacing: 12) {
            TextField("Record Type", text: $recordType)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 240)

            Stepper(value: $limit, in: 1...200, step: 10) {
                Text("Limit: \(limit)")
            }
            .frame(maxWidth: 200)

            Button("Run Query") { Task { await runQuery() } }
                .buttonStyle(.borderedProminent)
                .disabled(recordType.isEmpty)
        }
    }

    private func runQuery() async {
        loading = true
        loadError = nil
        defer { loading = false }
        do {
            records = try await service.queryRecords(recordType: recordType, limit: limit)
        } catch {
            loadError = error.localizedDescription
        }
    }
}

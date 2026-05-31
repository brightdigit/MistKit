//
//  SubscriptionsView.swift
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
  internal import MistDemoKit
  internal import SwiftUI

  /// View driving `subscriptions/list` and `subscriptions/lookup` against
  /// native CloudKit. Includes a "Create demo subscription" button so the
  /// list has something to render against a fresh container.
  internal struct SubscriptionsView: View {
    @Environment(CloudKitStore.self) private var service
    @State private var rows: [SubscriptionRow] = []
    @State private var loading = false
    @State private var loadError: String?
    @State private var lookupInput: String = ""

    internal var body: some View {
      Group {
        if loading {
          ProgressView("Loading subscriptions…")
        } else if let loadError {
          ContentUnavailableView(
            "Couldn't load subscriptions",
            systemImage: "exclamationmark.triangle",
            description: Text(loadError)
          )
        } else if rows.isEmpty {
          ContentUnavailableView(
            "No subscriptions yet",
            systemImage: "bell.slash",
            description: Text(
              "Tap Create Demo to register a Note-created subscription."
            )
          )
        } else {
          List(rows) { row in
            VStack(alignment: .leading, spacing: 2) {
              Text(row.id).font(.body.monospaced())
              Text(row.kind)
                .font(.caption)
                .foregroundStyle(.secondary)
              if let recordType = row.recordType {
                Text("Record type: \(recordType)")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
            .deleteSwipeAction {
              Task { await deleteSubscription(id: row.id) }
            }
          }
        }
      }
      .safeAreaInset(edge: .bottom) { lookupBar }
      .navigationTitle("Subscriptions")
      .toolbar {
        ToolbarItem {
          Button("Create Demo") { Task { await createDemo() } }
        }
        ToolbarItem {
          Button("Refresh") { Task { await refresh() } }
        }
      }
      .task { await refresh() }
    }

    private var lookupBar: some View {
      HStack {
        TextField(
          "Lookup IDs (comma-separated)",
          text: $lookupInput
        )
        .font(.body.monospaced())
        Button("Lookup") { Task { await runLookup() } }
          .disabled(lookupInput.isEmpty)
      }
      .padding(8)
      .background(.thinMaterial)
    }

    private func refresh() async {
      loading = true
      loadError = nil
      defer { loading = false }
      do {
        rows = try await service.loadSubscriptions()
      } catch {
        loadError = error.localizedDescription
      }
    }

    private func createDemo() async {
      do {
        _ = try await service.createDemoSubscription()
        await refresh()
      } catch {
        loadError = error.localizedDescription
      }
    }

    private func runLookup() async {
      let ids =
        lookupInput
        .split(separator: ",")
        .map { String($0).trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
      guard !ids.isEmpty else {
        return
      }
      loading = true
      loadError = nil
      defer { loading = false }
      do {
        rows = try await service.lookupSubscriptions(ids: ids)
      } catch {
        loadError = error.localizedDescription
      }
    }

    private func deleteSubscription(id: String) async {
      do {
        try await service.deleteSubscription(id: id)
        await refresh()
      } catch {
        loadError = error.localizedDescription
      }
    }
  }
#endif

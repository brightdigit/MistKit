//
//  ZoneListView.swift
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
  import MistDemoKit
  import SwiftUI

  /// View listing all CloudKit record zones.
  internal struct ZoneListView: View {
    @Environment(CloudKitStore.self) private var service
    @State private var zones: [ZoneRow] = []
    @State private var loading = false
    @State private var loadError: String?

    internal var body: some View {
      Group {
        if loading {
          ProgressView("Loading zones…")
        } else if let loadError {
          ContentUnavailableView(
            "Couldn't load zones",
            systemImage: "exclamationmark.triangle",
            description: Text(loadError)
          )
        } else if zones.isEmpty {
          ContentUnavailableView(
            "No zones yet",
            systemImage: "tray",
            description: Text(
              "Click Refresh to fetch zones from CloudKit."
            )
          )
        } else {
          List(zones) { zone in
            VStack(alignment: .leading, spacing: 4) {
              Text(zone.zoneName).font(.headline)
              Text("Owner: \(zone.ownerName)")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
          }
        }
      }
      .navigationTitle("Zones — \(service.databaseScope.label)")
      .toolbar {
        ToolbarItem {
          Button("Refresh") { Task { await refresh() } }
        }
      }
      .task { await refresh() }
      .onChange(of: service.databaseScope) { _, _ in
        zones = []
        Task { await refresh() }
      }
    }

    private func refresh() async {
      loading = true
      loadError = nil
      defer { loading = false }
      do {
        zones = try await service.loadZones()
      } catch {
        loadError = error.localizedDescription
      }
    }
  }
#endif

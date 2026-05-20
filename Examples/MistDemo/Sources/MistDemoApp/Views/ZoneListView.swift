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

#if canImport(SwiftUI) && canImport(CloudKit)
  internal import MistDemoKit
  internal import SwiftUI

  /// View listing all CloudKit record zones, with modify (create/delete)
  /// and changes (database-scope sync token) actions. Covers `zones/list`,
  /// `zones/lookup`, `zones/modify`, and `zones/changes` in one place.
  internal struct ZoneListView: View {
    @Environment(CloudKitStore.self) private var service
    @State private var zones: [ZoneRow] = []
    @State private var loading = false
    @State private var loadError: String?
    @State private var newZoneName: String = ""
    @State private var changesSnapshot: DatabaseChangesSnapshot?
    @State private var changesError: String?

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
            .deleteSwipeAction {
              Task { await deleteZone(named: zone.zoneName) }
            }
          }
        }
      }
      .safeAreaInset(edge: .bottom) { actionBar }
      .navigationTitle(service.databaseScope.label.map { "Zones — \($0)" } ?? "Zones")
      .toolbar {
        ToolbarItem {
          Button("Refresh") { Task { await refresh() } }
        }
        ToolbarItem {
          Button("Fetch Changes") { Task { await fetchChanges() } }
        }
      }
      .task { await refresh() }
      .onChange(of: service.databaseScope) { _, _ in
        zones = []
        Task { await refresh() }
      }
    }

    private var actionBar: some View {
      VStack(spacing: 4) {
        HStack {
          TextField(
            "New zone name", text: $newZoneName
          )
          .font(.body.monospaced())
          Button("Create") {
            Task { await createZone() }
          }
          .disabled(newZoneName.isEmpty)
        }
        if let snapshot = changesSnapshot {
          HStack {
            Text(
              "Changed \(snapshot.changedZoneIDs.count), "
                + "deleted \(snapshot.deletedZoneIDs.count)"
            )
            .font(.caption)
            Spacer()
            Text(snapshot.moreComing ? "more coming" : "in-sync")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        if let changesError {
          Text(changesError).font(.caption).foregroundStyle(.red)
        }
      }
      .padding(8)
      .background(.thinMaterial)
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

    private func createZone() async {
      do {
        _ = try await service.createZone(named: newZoneName)
        newZoneName = ""
        await refresh()
      } catch {
        loadError = error.localizedDescription
      }
    }

    private func deleteZone(named name: String) async {
      do {
        try await service.deleteZone(named: name)
        await refresh()
      } catch {
        loadError = error.localizedDescription
      }
    }

    private func fetchChanges() async {
      changesError = nil
      do {
        changesSnapshot = try await service.fetchDatabaseChanges(
          since: changesSnapshot?.serverChangeToken
        )
      } catch {
        changesError = error.localizedDescription
      }
    }
  }
#endif

//
//  RootView.swift
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

import CloudKit
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var service: NativeCloudKitService

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            Text("Pick a section from the sidebar.")
                .foregroundStyle(.secondary)
        }
        .task {
            await service.refreshAccountStatus()
        }
    }
}

struct SidebarView: View {
    @EnvironmentObject private var service: NativeCloudKitService
    @State private var selection: SidebarItem? = .account

    var body: some View {
        List(selection: $selection) {
            NavigationLink(value: SidebarItem.account) {
                Label("iCloud Account", systemImage: "person.crop.circle")
            }
            NavigationLink(value: SidebarItem.zones) {
                Label("Zones", systemImage: "tray.full")
            }
            NavigationLink(value: SidebarItem.query) {
                Label("Query Records", systemImage: "magnifyingglass")
            }
        }
        .navigationDestination(for: SidebarItem.self) { item in
            switch item {
            case .account:
                AccountView()
            case .zones:
                ZoneListView()
            case .query:
                QueryView()
            }
        }
        .navigationTitle("MistDemo (Native)")
    }
}

enum SidebarItem: Hashable {
    case account
    case zones
    case query
}

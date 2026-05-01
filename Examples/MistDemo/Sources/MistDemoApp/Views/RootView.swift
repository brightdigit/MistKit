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
public import SwiftUI

enum SidebarItem: Hashable, CaseIterable {
    case account
    case zones
    case query

    var label: String {
        switch self {
        case .account: return "iCloud Account"
        case .zones: return "Zones"
        case .query: return "Query Records"
        }
    }

    var systemImage: String {
        switch self {
        case .account: return "person.crop.circle"
        case .zones: return "tray.full"
        case .query: return "magnifyingglass"
        }
    }
}

public struct RootView: View {
    @EnvironmentObject private var service: NativeCloudKitService
    @State private var selection: SidebarItem? = .account

    public init() {}

    public var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            // The detail column needs its own NavigationStack so views like
            // QueryView can push to RecordDetailView via NavigationLink(value:).
            // Without this, NavigationLinks inside the detail column have no
            // "next column" to target.
            NavigationStack {
                DetailColumnRoot(selection: selection)
            }
        }
        .task {
            await service.refreshAccountStatus()
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarItem?

    var body: some View {
        List(SidebarItem.allCases, id: \.self, selection: $selection) { item in
            Label(item.label, systemImage: item.systemImage)
                .tag(item)
        }
        .navigationTitle("MistDemo (Native)")
    }
}

struct DetailColumnRoot: View {
    let selection: SidebarItem?

    var body: some View {
        switch selection {
        case .account:
            AccountView()
        case .zones:
            ZoneListView()
        case .query:
            QueryView()
        case nil:
            ContentUnavailableView(
                "Pick a section from the sidebar",
                systemImage: "sidebar.left",
                description: Text("Account, Zones, or Query Records")
            )
        }
    }
}

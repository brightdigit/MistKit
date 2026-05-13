//
//  RootView.swift
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
  public import SwiftUI

  /// Root view hosting the navigation split between sidebar and detail.
  public struct RootView: View {
    @Environment(CloudKitStore.self) private var service
    @State private var selection: SidebarItem? = .account

    /// The view body.
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

    /// Creates a new root view.
    public init() {}
  }
#endif

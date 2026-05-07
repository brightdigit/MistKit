//
//  DetailColumnRoot.swift
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

  /// Routes the sidebar selection to the appropriate detail view.
  internal struct DetailColumnRoot: View {
    internal let selection: SidebarItem?

    internal var body: some View {
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
#endif

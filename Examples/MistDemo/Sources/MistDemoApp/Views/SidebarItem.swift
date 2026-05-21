//
//  SidebarItem.swift
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

/// Sidebar navigation items for the MistDemo app.
internal enum SidebarItem: Hashable, CaseIterable {
  case account
  case zones
  case query
  case records
  case subscriptions
  case pushTokens
  case assets
  case users

  internal var label: String {
    switch self {
    case .account: return "iCloud Account"
    case .zones: return "Zones"
    case .query: return "Query Records"
    case .records: return "Records"
    case .subscriptions: return "Subscriptions"
    case .pushTokens: return "Push Tokens"
    case .assets: return "Assets"
    case .users: return "Users"
    }
  }

  internal var systemImage: String {
    switch self {
    case .account: return "person.crop.circle"
    case .zones: return "tray.full"
    case .query: return "magnifyingglass"
    case .records: return "doc.text"
    case .subscriptions: return "bell"
    case .pushTokens: return "key.radiowaves.forward"
    case .assets: return "photo"
    case .users: return "person.2"
    }
  }
}

//
//  RemoteNotificationRegistering.swift
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

#if canImport(SwiftUI)
  public import SwiftUI

  /// Unifies the per-platform "register for remote notifications" entry point
  /// so push code can call it through ``PlatformApplication`` without
  /// branching. The accessor is named `sharedApplication` rather than `shared`
  /// because `WKApplication.shared()` is a method, not a property — reusing the
  /// `shared` name would collide with it.
  @MainActor
  internal protocol RemoteNotificationRegistering {
    static var sharedApplication: PlatformApplication { get }
    func registerForRemoteNotifications()
  }

  extension RemoteNotificationRegistering {
    /// Registers the shared platform application for remote notifications —
    /// the single cross-platform entry point push code calls.
    internal static func registerSharedForRemoteNotifications() {
      sharedApplication.registerForRemoteNotifications()
    }
  }

  #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    extension NSApplication: RemoteNotificationRegistering {
      internal static var sharedApplication: NSApplication { shared }
    }
  #elseif canImport(WatchKit)
    extension WKApplication: RemoteNotificationRegistering {
      internal static var sharedApplication: WKApplication { shared() }
    }
  #elseif canImport(UIKit)
    extension UIApplication: RemoteNotificationRegistering {
      internal static var sharedApplication: UIApplication { shared }
    }
  #endif
#endif

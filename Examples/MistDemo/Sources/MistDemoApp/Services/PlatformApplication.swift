//
//  PlatformApplication.swift
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

  // The filename-matching `PlatformApplication` typealias necessarily sits
  // beside the other per-platform typealiases (a `#if` ladder can't be
  // reordered to satisfy file_types_order), so the rule is disabled for the
  // typealias/protocol region and re-enabled at the end of the file.
  // swiftlint:disable file_types_order

  #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    public import AppKit

    /// The platform application type (`NSApplication` on AppKit,
    /// `UIApplication` on UIKit, `WKApplication` on watchOS). Lets the
    /// push-notification delegate and registration call sites name one type
    /// instead of branching.
    public typealias PlatformApplication = NSApplication

    /// The platform application delegate protocol matching
    /// ``PlatformApplication``.
    public typealias ApplicationDelegate = NSApplicationDelegate

    /// SwiftUI's delegate-adaptor property wrapper matching
    /// ``ApplicationDelegate``. Lets `@main` declare the adaptor once
    /// rather than under parallel `#if` branches.
    public typealias PlatformApplicationDelegateAdaptor = NSApplicationDelegateAdaptor
  #elseif canImport(WatchKit)
    public import WatchKit

    /// The platform application type. See the AppKit branch for full notes.
    public typealias PlatformApplication = WKApplication

    /// The platform application delegate protocol matching
    /// ``PlatformApplication``.
    public typealias ApplicationDelegate = WKApplicationDelegate

    /// SwiftUI's delegate-adaptor property wrapper matching
    /// ``ApplicationDelegate``.
    public typealias PlatformApplicationDelegateAdaptor = WKApplicationDelegateAdaptor
  #elseif canImport(UIKit)
    public import UIKit

    /// The platform application type. See the AppKit branch for full notes.
    public typealias PlatformApplication = UIApplication

    /// The platform application delegate protocol matching
    /// ``PlatformApplication``.
    public typealias ApplicationDelegate = UIApplicationDelegate

    /// SwiftUI's delegate-adaptor property wrapper matching
    /// ``ApplicationDelegate``.
    public typealias PlatformApplicationDelegateAdaptor = UIApplicationDelegateAdaptor
  #endif

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

// swiftlint:enable file_types_order

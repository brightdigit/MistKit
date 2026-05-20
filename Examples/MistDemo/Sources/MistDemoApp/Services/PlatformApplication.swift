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

// Per-platform typealiases for the same logical names mean the
// file has parallel "main_type" declarations under different `#if`
// branches, which the rule mis-flags.
// swiftlint:disable file_types_order

// Remote-notification registration is available on AppKit (non-Catalyst),
// iOS, tvOS, Catalyst, and visionOS — but NOT watchOS, where `UIApplication`
// and its delegate are unavailable even though UIKit imports. This combined
// condition is the single source of truth for "the platform has APNs
// registration"; every push call site guards on the same shape.
#if (canImport(AppKit) && !targetEnvironment(macCatalyst)) || (canImport(UIKit) && !os(watchOS))
  public import SwiftUI

  #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    public import AppKit

    /// The platform application type (`NSApplication` on AppKit,
    /// `UIApplication` on UIKit). Lets the push-notification delegate and
    /// registration call sites name one type instead of branching.
    public typealias PlatformApplication = NSApplication

    /// The platform application delegate protocol matching
    /// ``PlatformApplication``.
    public typealias PlatformApplicationDelegate = NSApplicationDelegate

    /// SwiftUI's delegate-adaptor property wrapper matching
    /// ``PlatformApplicationDelegate``. Lets `@main` declare the adaptor once
    /// rather than under parallel `#if` branches.
    public typealias PlatformApplicationDelegateAdaptor = NSApplicationDelegateAdaptor
  #elseif canImport(UIKit) && !os(watchOS)
    public import UIKit

    /// The platform application type. See the AppKit branch for full notes.
    public typealias PlatformApplication = UIApplication

    /// The platform application delegate protocol matching
    /// ``PlatformApplication``.
    public typealias PlatformApplicationDelegate = UIApplicationDelegate

    /// SwiftUI's delegate-adaptor property wrapper matching
    /// ``PlatformApplicationDelegate``.
    public typealias PlatformApplicationDelegateAdaptor = UIApplicationDelegateAdaptor
  #endif

  /// Unifies the per-platform "register for remote notifications" entry point
  /// so push code can call it through ``PlatformApplication`` without
  /// branching. Both `NSApplication` and `UIApplication` already expose this
  /// surface; the protocol just names the shared shape.
  @MainActor
  internal protocol RemoteNotificationRegistering {
    static var shared: PlatformApplication { get }
    func registerForRemoteNotifications()
  }

  extension RemoteNotificationRegistering {
    /// Registers the shared platform application for remote notifications —
    /// the single cross-platform entry point push code calls.
    internal static func registerSharedForRemoteNotifications() {
      shared.registerForRemoteNotifications()
    }
  }

  extension PlatformApplication: RemoteNotificationRegistering {}
#endif

// swiftlint:enable file_types_order

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

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  public import AppKit

  /// The platform application type (`NSApplication` on AppKit,
  /// `UIApplication` on UIKit). Used so the demo's push-notification
  /// delegate can implement the
  /// `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`-style
  /// hooks once instead of twice. Public so the executable target's `@main`
  /// can reach `PushNotificationDelegate` (which conforms via the matching
  /// `PlatformApplicationDelegate` alias).
  public typealias PlatformApplication = NSApplication

  /// The platform application delegate protocol matching
  /// ``PlatformApplication``.
  public typealias PlatformApplicationDelegate = NSApplicationDelegate
#elseif canImport(UIKit)
  public import UIKit

  /// The platform application type (`NSApplication` on AppKit,
  /// `UIApplication` on UIKit). See the AppKit branch for full notes.
  public typealias PlatformApplication = UIApplication

  /// The platform application delegate protocol matching
  /// ``PlatformApplication``.
  public typealias PlatformApplicationDelegate = UIApplicationDelegate
#endif

// swiftlint:enable file_types_order

//
//  PushNotificationDelegate.swift
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
  public import Foundation

  #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    public import AppKit
  #elseif canImport(WatchKit)
    public import WatchKit
  #elseif canImport(UIKit) && !os(watchOS)
    public import UIKit
  #endif

  /// Universal AppKit/UIKit/watchOS delegate that catches APNs callbacks
  /// SwiftUI can't observe directly. SwiftUI's `@NSApplicationDelegateAdaptor`
  /// / `@UIApplicationDelegateAdaptor` / `@WKApplicationDelegateAdaptor`
  /// instantiates this with the parameterless `NSObject` init, so the receiver
  /// is wired via a `static weak` set by `CloudKitStore.init` rather than
  /// passed in.
  ///
  /// The APNs callbacks themselves are supplied by
  /// ``PlatformApplicationDelegate`` and its per-platform extensions;
  /// conforming to both that protocol and the system ``ApplicationDelegate``
  /// (required by the SwiftUI adaptor) is all this class needs to declare.
  @MainActor
  public final class PushNotificationDelegate:
    NSObject, ApplicationDelegate, PlatformApplicationDelegate
  {
    /// The object the platform delegate forwards APNs callbacks to. Set by
    /// `CloudKitStore.init`; held weakly so the store's lifetime governs it.
    public static weak var receiver: (any PushTokenReceiver)?

    /// Required by SwiftUI's delegate adaptor, which constructs the
    /// delegate with no arguments at app launch.
    override public init() {
      super.init()
    }

    // MARK: - Obj-C bridge for system-delegate optional selectors
    //
    // Swift forbids `@objc` on protocol extension members, so the
    // ``PlatformApplicationDelegate`` defaults can't directly satisfy the
    // optional `@objc` requirements on the system delegate protocols. These
    // concrete shims expose the selectors to the Obj-C runtime so AppKit /
    // UIKit / WatchKit dispatch lands on this class, and forward to the
    // same `static weak receiver` the protocol extensions use.

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
      /// APNs delivered a device token (AppKit variant).
      @objc
      public func application(
        _ application: NSApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
      ) {
        Self.receiver?.didRegisterForRemoteNotifications(deviceToken: deviceToken)
      }

      /// APNs refused registration (AppKit variant).
      @objc
      public func application(
        _ application: NSApplication,
        didFailToRegisterForRemoteNotificationsWithError error: any Error
      ) {
        Self.receiver?.didFailToRegisterForRemoteNotifications(error: error)
      }

      /// A remote notification arrived (AppKit variant).
      @objc
      public func application(
        _ application: NSApplication,
        didReceiveRemoteNotification userInfo: [String: Any]
      ) {
        Self.receiver?.didReceiveRemoteNotification(userInfo: userInfo)
      }
    #elseif canImport(UIKit) && !os(watchOS)
      /// APNs delivered a device token (UIKit variant).
      @objc
      public func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
      ) {
        Self.receiver?.didRegisterForRemoteNotifications(deviceToken: deviceToken)
      }

      /// APNs refused registration (UIKit variant).
      @objc
      public func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: any Error
      ) {
        Self.receiver?.didFailToRegisterForRemoteNotifications(error: error)
      }

      /// A remote notification arrived (UIKit variant).
      @objc
      public func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
      ) {
        Self.receiver?.didReceiveRemoteNotification(userInfo: userInfo)
        completionHandler(.newData)
      }
    #elseif canImport(WatchKit)
      /// APNs delivered a device token (watchOS variant).
      @objc
      public func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        Self.receiver?.didRegisterForRemoteNotifications(deviceToken: deviceToken)
      }

      /// APNs refused registration (watchOS variant).
      @objc
      public func didFailToRegisterForRemoteNotificationsWithError(_ error: any Error) {
        Self.receiver?.didFailToRegisterForRemoteNotifications(error: error)
      }

      /// A remote notification arrived (watchOS variant).
      @objc
      public func didReceiveRemoteNotification(
        _ userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (WKBackgroundFetchResult) -> Void
      ) {
        Self.receiver?.didReceiveRemoteNotification(userInfo: userInfo)
        completionHandler(.newData)
      }
    #endif
  }
#endif

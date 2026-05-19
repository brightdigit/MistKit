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

#if canImport(AppKit) || canImport(UIKit)
  public import Foundation

  #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    public import AppKit
  #elseif canImport(UIKit)
    public import UIKit
  #endif

  /// Universal AppKit/UIKit delegate that catches APNs callbacks SwiftUI
  /// can't observe directly. SwiftUI's `@NSApplicationDelegateAdaptor` /
  /// `@UIApplicationDelegateAdaptor` instantiates this with the parameterless
  /// `NSObject` init, so the receiver is wired via a `static weak` set by
  /// `CloudKitStore.init` rather than passed in.
  @MainActor
  public final class PushNotificationDelegate: NSObject, PlatformApplicationDelegate {
    internal static weak var receiver: (any PushTokenReceiver)?

    /// Required by SwiftUI's delegate adaptor, which constructs the
    /// delegate with no arguments at app launch.
    override public init() {
      super.init()
    }

    /// APNs delivered a device token — forward it to the registered receiver.
    public func application(
      _ application: PlatformApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
      Self.receiver?.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    /// APNs refused registration — forward the error to the receiver so it
    /// can surface in the UI.
    public func application(
      _ application: PlatformApplication,
      didFailToRegisterForRemoteNotificationsWithError error: any Error
    ) {
      Self.receiver?.didFailToRegisterForRemoteNotifications(error: error)
    }

    // Inbound notification signatures genuinely differ between platforms —
    // UIKit takes a fetch-completion handler, AppKit does not. Both branches
    // funnel through the same receiver method.
    #if canImport(UIKit) && !canImport(AppKit)
      /// A remote notification arrived (UIKit variant).
      public func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
      ) {
        Self.receiver?.didReceiveRemoteNotification(userInfo: userInfo)
        completionHandler(.newData)
      }
    #elseif canImport(AppKit) && !targetEnvironment(macCatalyst)
      /// A remote notification arrived (AppKit variant).
      public func application(
        _ application: NSApplication,
        didReceiveRemoteNotification userInfo: [String: Any]
      ) {
        Self.receiver?.didReceiveRemoteNotification(userInfo: userInfo)
      }
    #endif
  }
#endif

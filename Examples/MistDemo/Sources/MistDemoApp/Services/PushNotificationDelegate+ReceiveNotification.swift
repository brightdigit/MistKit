//
//  PushNotificationDelegate+ReceiveNotification.swift
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

// The inbound `didReceiveRemoteNotification` delegate selector genuinely
// differs between platforms — UIKit hands back a fetch-completion handler,
// AppKit does not — so each variant lives in its own platform extension
// rather than as inline `#if` branches inside the delegate class. Both funnel
// through the same `PushTokenReceiver` method.

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  public import AppKit
  public import Foundation

  extension PushNotificationDelegate {
    /// A remote notification arrived (AppKit variant).
    public func application(
      _ application: NSApplication,
      didReceiveRemoteNotification userInfo: [String: Any]
    ) {
      Self.receiver?.didReceiveRemoteNotification(userInfo: userInfo)
    }
  }
#elseif canImport(UIKit) && !os(watchOS)
  public import Foundation
  public import UIKit

  extension PushNotificationDelegate {
    /// A remote notification arrived (UIKit variant).
    public func application(
      _ application: UIApplication,
      didReceiveRemoteNotification userInfo: [AnyHashable: Any],
      fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
      Self.receiver?.didReceiveRemoteNotification(userInfo: userInfo)
      completionHandler(.newData)
    }
  }
#endif

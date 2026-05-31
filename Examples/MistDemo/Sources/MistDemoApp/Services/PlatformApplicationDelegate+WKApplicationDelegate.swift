//
//  PlatformApplicationDelegate+WKApplicationDelegate.swift
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

#if canImport(WatchKit)
  internal import Foundation
  public import WatchKit

  extension PlatformApplicationDelegate where Self: WKApplicationDelegate {
    /// APNs delivered a device token — forward it to the registered receiver.
    public func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
      Self.receiver?.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    /// APNs refused registration — forward the error to the receiver.
    public func didFailToRegisterForRemoteNotificationsWithError(_ error: any Error) {
      Self.receiver?.didFailToRegisterForRemoteNotifications(error: error)
    }

    /// A remote notification arrived (watchOS variant).
    public func didReceiveRemoteNotification(
      _ userInfo: [AnyHashable: Any],
      fetchCompletionHandler completionHandler: @escaping (WKBackgroundFetchResult) -> Void
    ) {
      Self.receiver?.didReceiveRemoteNotification(userInfo: userInfo)
      completionHandler(.newData)
    }
  }
#endif

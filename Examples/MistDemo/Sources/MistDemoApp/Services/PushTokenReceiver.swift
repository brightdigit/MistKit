//
//  PushTokenReceiver.swift
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

// `@objc` requires the Objective-C runtime, which is absent on
// Linux/Windows. The push-notification bridge is Apple-only, so gate the
// whole protocol on Objective-C interop availability.
#if canImport(ObjectiveC)
  public import Foundation

  /// Receiver side of the platform push-notification bridge. The
  /// `PushNotificationDelegate` (AppKit / UIKit) forwards OS callbacks
  /// to whatever object is currently registered as
  /// `PushNotificationDelegate.receiver`.
  @MainActor
  @objc
  public protocol PushTokenReceiver: AnyObject {
    func didRegisterForRemoteNotifications(deviceToken: Data)
    func didFailToRegisterForRemoteNotifications(error: any Error)
    func didReceiveRemoteNotification(userInfo: [AnyHashable: Any])
  }
#endif

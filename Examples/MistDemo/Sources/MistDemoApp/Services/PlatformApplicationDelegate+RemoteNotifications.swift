//
//  PlatformApplicationDelegate+RemoteNotifications.swift
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

#if (canImport(AppKit) && !targetEnvironment(macCatalyst)) || (canImport(UIKit) && !os(watchOS))
  public import Foundation

  extension PlatformApplicationDelegate {
    /// APNs delivered a device token — forward it to the registered receiver.
    ///
    /// Cannot be `@objc` (Swift forbids `@objc` on protocol extension
    /// members); the optional system-delegate selector is bridged by a
    /// concrete `@objc` shim on ``PushNotificationDelegate`` that
    /// delegates here.
    public func application(
      _: PlatformApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
      Self.receiver?.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    /// APNs refused registration — forward the error to the receiver so it
    /// can surface in the UI.
    public func application(
      _: PlatformApplication,
      didFailToRegisterForRemoteNotificationsWithError error: any Error
    ) {
      Self.receiver?.didFailToRegisterForRemoteNotifications(error: error)
    }
  }
#endif

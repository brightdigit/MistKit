//
//  CloudKitStore+PushTokens.swift
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

#if canImport(CloudKit)
  internal import CloudKit
  internal import Foundation
  internal import MistDemoKit

  #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    internal import AppKit
  #elseif canImport(UIKit)
    internal import UIKit
  #endif

  /// The push-token registration state surfaced to the UI. APNs requires a
  /// signed app + push entitlement; on simulators or unentitled builds the
  /// OS reports an error which the UI renders inline.
  internal enum PushTokenStatus: Sendable {
    case idle
    case requesting
    case registered(hexToken: String)
    case failed(message: String)
  }

  extension CloudKitStore {
    /// Trigger APNs registration. Returns immediately after asking the OS;
    /// the actual token arrives via the platform app delegate hook, which
    /// the demo app forwards back into the store via `recordDeviceToken`.
    /// On platforms where APNs isn't available we report `.failed`.
    internal func requestPushNotificationRegistration() {
      #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        NSApplication.shared.registerForRemoteNotifications()
        pushTokenStatus = .requesting
      #elseif canImport(UIKit)
        UIApplication.shared.registerForRemoteNotifications()
        pushTokenStatus = .requesting
      #else
        pushTokenStatus = .failed(
          message: "APNs registration is unavailable on this platform."
        )
      #endif
    }

    /// Forward the APNs device token captured by the platform app delegate.
    internal func recordDeviceToken(_ data: Data) {
      let hex = data.map { String(format: "%02x", $0) }.joined()
      pushTokenStatus = .registered(hexToken: hex)
    }

    /// Forward the APNs registration error captured by the platform app delegate.
    /// Surfaces the underlying NSError domain + code alongside the localized
    /// message — the default `localizedDescription` for sandboxed-app /
    /// signing failures collapses to "the operation couldn't be completed.
    /// (OSStatus error N)" which by itself doesn't say what failed.
    internal func recordDeviceTokenError(_ error: any Error) {
      let nsError = error as NSError
      let summary =
        "\(error.localizedDescription)\n"
        + "[\(nsError.domain) code \(nsError.code)]"
      pushTokenStatus = .failed(message: summary)
    }
  }

  #if canImport(AppKit) || canImport(UIKit)
    extension CloudKitStore: PushTokenReceiver {
      internal func didRegisterForRemoteNotifications(deviceToken: Data) {
        recordDeviceToken(deviceToken)
      }

      internal func didFailToRegisterForRemoteNotifications(error: any Error) {
        recordDeviceTokenError(error)
      }

      internal func didReceiveRemoteNotification(userInfo: [AnyHashable: Any]) {
        lastReceivedNotification = String(describing: userInfo)
      }
    }
  #endif
#endif

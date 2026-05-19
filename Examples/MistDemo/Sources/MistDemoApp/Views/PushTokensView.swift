//
//  PushTokensView.swift
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

#if canImport(SwiftUI) && canImport(CloudKit)
  internal import MistDemoKit
  internal import SwiftUI

  /// Surfaces the device's APNs token for cross-reference with the REST
  /// `tokens/create` / `tokens/register` workflows. The native demo uses
  /// the CloudKit framework, so the token here is informational only:
  /// iCloud routes pushes to the signed-in user's devices without anyone
  /// passing the device token to CloudKit. See the Subscriptions view for
  /// the actual server-side notification setup.
  internal struct PushTokensView: View {
    @Environment(CloudKitStore.self) private var service

    internal var body: some View {
      Form {
        Section {
          tokenStatus
          Button("Register for Remote Notifications") {
            service.requestPushNotificationRegistration()
          }
        } header: {
          Text("APNs device token")
        } footer: {
          Text(
            "Real push delivery requires a signed build with the push "
              + "entitlement and a paid developer account. Simulators and "
              + "unentitled builds surface the registration error path "
              + "below instead of a token. The native CloudKit framework "
              + "binds this token to the signed-in iCloud account "
              + "automatically — to actually receive a push, create a "
              + "CKSubscription from the Subscriptions tab. The MistKit "
              + "REST tokens/create + tokens/register endpoints exist for "
              + "server-side scenarios where there's no iCloud user "
              + "context to route through."
          )
          .font(.caption)
        }
        if let payload = service.lastReceivedNotification {
          Section {
            Text(payload)
              .font(.callout.monospaced())
              #if !os(tvOS) && !os(watchOS)
                .textSelection(.enabled)
              #endif
          } header: {
            Text("Last received remote notification")
          }
        }
      }
      .formStyle(.grouped)
      .navigationTitle("Push Tokens")
    }

    @ViewBuilder
    private var tokenStatus: some View {
      switch service.pushTokenStatus {
      case .idle:
        LabeledContent("APNs Token", value: "Not requested yet")
      case .requesting:
        HStack {
          ProgressView().controlSize(.small)
          Text("Requesting…")
        }
      case .registered(let hex):
        LabeledContent("APNs Token") {
          Text(hex)
            .font(.callout.monospaced())
            .lineLimit(3)
            .truncationMode(.middle)
            #if !os(tvOS) && !os(watchOS)
              .textSelection(.enabled)
            #endif
        }
      case .failed(let message):
        LabeledContent("APNs Token", value: "Failed")
        Text(message).font(.caption).foregroundStyle(.red)
      }
    }
  }
#endif

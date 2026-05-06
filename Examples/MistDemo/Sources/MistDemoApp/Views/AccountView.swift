//
//  AccountView.swift
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

#if canImport(SwiftUI) && canImport(CloudKit) && !os(tvOS) && !os(watchOS)
  import CloudKit
  import SwiftUI

  #if canImport(AppKit)
    import AppKit
  #elseif canImport(UIKit)
    import UIKit
  #endif

  /// View for managing the iCloud account and web auth token.
  internal struct AccountView: View {
    /// Where the current `apiToken` value came from on this launch.
    internal enum TokenSource {
      case manual
      case environment
    }

    /// Env var name the MistDemo CLI also reads.
    internal static let envVarName = "CLOUDKIT_API_TOKEN"

    @EnvironmentObject internal var service: NativeCloudKitService
    @AppStorage("MistDemoApp.cloudKitApiToken") internal var apiToken: String = ""
    @State internal var webAuthToken: String?
    @State internal var fetchingWebAuthToken = false
    @State internal var webAuthTokenError: String?
    @State internal var tokenSource: TokenSource = .manual

    internal var body: some View {
      Form {
        containerSection
        webAuthTokenSection
        if let error = service.lastError {
          Section("Last Service Error") {
            Text(error).font(.callout).foregroundStyle(.red)
          }
        }
      }
      .formStyle(.grouped)
      .navigationTitle("iCloud Account")
      .toolbar {
        ToolbarItem {
          Button("Refresh") {
            Task { await service.refreshAccountStatus() }
          }
        }
      }
      .onAppear { seedTokenIfNeeded() }
    }

    private var sourceCaption: String? {
      switch tokenSource {
      case .manual:
        return nil
      case .environment:
        return
          "Loaded from $\(Self.envVarName) (xcodegen baked it into the scheme from .env)."
      }
    }

    private var statusLabel: String {
      switch service.accountStatus {
      case .available: return "Available"
      case .noAccount: return "No iCloud Account"
      case .restricted: return "Restricted"
      case .couldNotDetermine: return "Could Not Determine"
      case .temporarilyUnavailable: return "Temporarily Unavailable"
      @unknown default: return "Unknown"
      }
    }

    private var containerSection: some View {
      Section("Container") {
        LabeledContent("Container", value: service.containerIdentifier)
        LabeledContent("Database", value: "Private")
        LabeledContent("iCloud Status", value: statusLabel)
      }
    }

    private var webAuthTokenSection: some View {
      Section {
        tokenTextField
        tokenActions
        tokenDisplay
      } header: {
        Text("Web Auth Token")
      } footer: {
        Text(
          "Issues the same `158__…` token that MistKit / "
            + "`mistdemo auth-token` consume. "
            + "Uses CKFetchWebAuthTokenOperation."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }

    private var tokenTextField: some View {
      Group {
        TextField(
          "CloudKit API Token",
          text: $apiToken,
          prompt: Text("Paste from CloudKit Dashboard")
        )
        .textFieldStyle(.roundedBorder)
        .font(.body.monospaced())
        .onChange(of: apiToken) { _, _ in tokenSource = .manual }
        #if os(iOS)
          .autocorrectionDisabled(true)
          .textInputAutocapitalization(.never)
        #endif
        if let caption = sourceCaption {
          Text(caption).font(.caption).foregroundStyle(.secondary)
        }
      }
    }

    private var tokenActions: some View {
      HStack {
        Button {
          Task { await fetchToken() }
        } label: {
          if fetchingWebAuthToken {
            HStack(spacing: 6) {
              ProgressView().controlSize(.small)
              Text("Fetching…")
            }
          } else {
            Text("Fetch Web Auth Token")
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(apiToken.isEmpty || fetchingWebAuthToken)
        if webAuthToken != nil {
          Button("Clear", role: .destructive) {
            webAuthToken = nil
            webAuthTokenError = nil
          }
        }
      }
    }

    @ViewBuilder
    private var tokenDisplay: some View {
      if let webAuthToken {
        LabeledContent("Web Auth Token") {
          VStack(alignment: .trailing, spacing: 6) {
            Text(webAuthToken)
              .font(.callout.monospaced())
              .lineLimit(3)
              .truncationMode(.middle)
              .textSelection(.enabled)
            Button("Copy") { copy(webAuthToken) }
              .buttonStyle(.bordered)
              .controlSize(.small)
          }
        }
      }
      if let webAuthTokenError {
        Text(webAuthTokenError).font(.callout).foregroundStyle(.red)
      }
    }
  }
#endif

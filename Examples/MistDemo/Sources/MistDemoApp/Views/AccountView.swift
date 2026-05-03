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

  struct AccountView: View {
    @EnvironmentObject private var service: NativeCloudKitService

    /// The CloudKit API token (the public token from CloudKit Dashboard).
    /// Persisted across launches because re-pasting it during a presentation
    /// is annoying. This is the same value the MistDemo CLI calls
    /// `--api-token` / `CLOUDKIT_API_TOKEN`.
    @AppStorage("MistDemoApp.cloudKitApiToken") private var apiToken: String = ""

    @State private var webAuthToken: String?
    @State private var fetchingWebAuthToken = false
    @State private var webAuthTokenError: String?
    @State private var tokenSource: TokenSource = .manual

    /// Where the current `apiToken` value came from on this launch — used
    /// for the small caption beneath the TextField so the provenance is
    /// obvious during the presentation.
    private enum TokenSource {
      case manual
      case environment
    }

    /// Env var name the MistDemo CLI also reads (defined in
    /// MistDemoConstants.EnvironmentVars.cloudKitAPIToken). Hard-coded here
    /// because MistDemoApp deliberately has no MistKit dependency.
    ///
    /// At launch the value reaches `ProcessInfo` through one of:
    ///   * `make generate` substitutes `${CLOUDKIT_API_TOKEN}` from the
    ///     repo-local `.env` (gitignored) into the scheme's
    ///     `environmentVariables` (the whole .xcodeproj is gitignored
    ///     repo-wide, so the substituted value never lands in git).
    ///   * Or the app is launched from a shell that already exports it
    ///     (e.g. `CLOUDKIT_API_TOKEN=… swift run MistDemoApp`).
    private static let envVarName = "CLOUDKIT_API_TOKEN"

    var body: some View {
      // swiftlint:disable:next closure_body_length
      Form {
        Section("Container") {
          LabeledContent("Container", value: service.containerIdentifier)
          LabeledContent("Database", value: "Private")
          LabeledContent("iCloud Status", value: statusLabel)
        }

        Section {
          TextField(
            "CloudKit API Token", text: $apiToken, prompt: Text("Paste from CloudKit Dashboard")
          )
          .textFieldStyle(.roundedBorder)
          .font(.body.monospaced())
          .onChange(of: apiToken) { _, _ in
            // If the user edits the field, anything they type
            // is "manual" — drop the seeded-from-env caption.
            tokenSource = .manual
          }
          #if os(iOS)
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
          #endif

          if let caption = sourceCaption {
            Text(caption)
              .font(.caption)
              .foregroundStyle(.secondary)
          }

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
        } header: {
          Text("Web Auth Token")
        } footer: {
          Text(
            "Issues the same `158__…` token that MistKit / `mistdemo auth-token` consume — useful for handing off to a server-side or CLI process. Uses CKFetchWebAuthTokenOperation."
          )
          .font(.caption)
          .foregroundStyle(.secondary)
        }

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

    /// Seed `apiToken` from the environment on first appear, but never
    /// overwrite a value the user has already pasted.
    private func seedTokenIfNeeded() {
      guard apiToken.isEmpty else { return }

      if let envValue = ProcessInfo.processInfo.environment[Self.envVarName],
        !envValue.isEmpty,
        // When `.env` wasn't sourced before `make generate`, xcodegen
        // leaves the literal placeholder string in the scheme. Treat
        // that as unset so the TextField stays empty.
        !envValue.hasPrefix("${")
      {
        apiToken = envValue
        tokenSource = .environment
      }
    }

    private var sourceCaption: String? {
      switch tokenSource {
      case .manual:
        return nil
      case .environment:
        return "Loaded from $\(Self.envVarName) (xcodegen baked it into the scheme from .env)."
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

    private func fetchToken() async {
      fetchingWebAuthToken = true
      webAuthTokenError = nil
      webAuthToken = nil
      defer { fetchingWebAuthToken = false }
      do {
        let token = try await service.fetchWebAuthToken(
          apiToken: apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        webAuthToken = token
      } catch {
        webAuthTokenError = error.localizedDescription
      }
    }

    private func copy(_ value: String) {
      #if canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
      #elseif canImport(UIKit)
        UIPasteboard.general.string = value
      #endif
    }
  }
#endif

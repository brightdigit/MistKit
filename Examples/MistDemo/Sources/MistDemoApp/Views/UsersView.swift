//
//  UsersView.swift
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

  /// View driving `users/discover`, `users/lookup/email`, and
  /// `users/lookup/id` against native CloudKit. CloudKit only returns
  /// identities the caller is permitted to discover, so empty results
  /// here usually mean the lookup target hasn't opted in to discovery.
  internal struct UsersView: View {
    @Environment(CloudKitStore.self) private var service
    @State private var emailInput: String = ""
    @State private var recordNameInput: String = ""
    @State private var discoverInput: String = ""
    @State private var results: [UserIdentityRow] = []
    @State private var error: String?
    @State private var loading = false

    internal var body: some View {
      Form {
        emailSection
        recordNameSection
        discoverSection
        if let error {
          Section {
            Text(error).font(.callout).foregroundStyle(.red)
          }
        }
        if !results.isEmpty {
          resultsSection
        }
      }
      .formStyle(.grouped)
      .navigationTitle("Users")
    }

    private var emailSection: some View {
      Section {
        TextField("Email address", text: $emailInput)
        Button("Lookup by Email") {
          Task { await lookupByEmail() }
        }
        .disabled(emailInput.isEmpty || loading)
      } header: {
        Text("users/lookup/email")
      }
    }

    private var recordNameSection: some View {
      Section {
        TextField("User record name", text: $recordNameInput)
          .font(.body.monospaced())
        Button("Lookup by Record Name") {
          Task { await lookupByRecordName() }
        }
        .disabled(recordNameInput.isEmpty || loading)
      } header: {
        Text("users/lookup/id")
      }
    }

    private var discoverSection: some View {
      Section {
        TextField("Comma-separated emails", text: $discoverInput)
        Button("Discover") {
          Task { await discover() }
        }
        .disabled(discoverInput.isEmpty || loading)
      } header: {
        Text("users/discover (POST)")
      } footer: {
        Text(
          "CloudKit JS exposes a per-email primitive only; the batch "
            + "POST surface is composed by looping the per-call API."
        )
        .font(.caption)
      }
    }

    private var resultsSection: some View {
      Section("Results") {
        ForEach(results) { row in
          VStack(alignment: .leading, spacing: 2) {
            Text(row.displayName ?? "(no display name)")
              .font(.headline)
            if let recordName = row.recordName {
              Text(recordName).font(.caption.monospaced())
                .foregroundStyle(.secondary)
            }
            if let hint = row.lookupHint {
              Text("Looked up via: \(hint)")
                .font(.caption).foregroundStyle(.secondary)
            }
          }
        }
      }
    }

    private func lookupByEmail() async {
      await runLookup {
        if let row = try await service.lookupUser(byEmail: emailInput) {
          return [row]
        }
        return []
      }
    }

    private func lookupByRecordName() async {
      await runLookup {
        if let row = try await service.lookupUser(
          byRecordName: recordNameInput
        ) {
          return [row]
        }
        return []
      }
    }

    private func discover() async {
      let emails =
        discoverInput
        .split(separator: ",")
        .map { String($0).trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
      await runLookup {
        try await service.discoverUsers(byEmails: emails)
      }
    }

    private func runLookup(
      _ operation: @Sendable () async throws -> [UserIdentityRow]
    ) async {
      loading = true
      error = nil
      defer { loading = false }
      do {
        results = try await operation()
      } catch {
        results = []
        self.error = error.localizedDescription
      }
    }
  }
#endif

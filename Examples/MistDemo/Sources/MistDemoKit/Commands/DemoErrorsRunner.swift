//
//  DemoErrorsRunner.swift
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

import Foundation
import MistKit

/// Runs the talk's CloudKit error scenarios (401, 404, 409) and prints typed
/// `CloudKitError` details. Mirrors the section/prefix style of
/// `IntegrationTestRunner`.
internal struct DemoErrorsRunner {
  internal let config: MistDemoConfig

  /// Record type used by 404 and 409 demos. The 404 type is unlikely to exist;
  /// the 409 type is the same `Note` schema used by other MistDemo commands.
  private static let bogusRecordType = "DefinitelyNotARealType_DemoErrorsCommand_xyz"
  private static let conflictRecordType = "Note"

  internal func run(scenario: ErrorScenario) async {
    printRunnerHeader()
    switch scenario {
    case .all:
      await runUnauthorized()
      await runNotFound()
      await runConflict()
    case .unauthorized:
      await runUnauthorized()
    case .notFound:
      await runNotFound()
    case .conflict:
      await runConflict()
    }
    printRunnerFooter()
  }

  // MARK: - 401 Unauthorized

  /// Demonstrates 401 by constructing a CloudKitService with deliberate placeholder
  /// tokens. The user's real config is never mutated. The 401 demo is pinned to
  /// `.private` because web-auth tokens are the most representative CloudKit
  /// credential failure.
  internal func runUnauthorized() async {
    printSectionHeader("401 — Unauthorized (invalid credentials)")
    do {
      let service = try MistKitClientFactory.create(
        from: config.with(database: .private),
        tokenManager: MistKitClientFactory.makeBadCredentialsTokenManager()
      )
      _ = try await service.fetchCurrentUser()
      print("⚠️  Expected 401 but call succeeded — credentials may not be validated server-side.")
    } catch let error as CloudKitError {
      printCloudKitError(error, expectedStatus: 401)
      print(
        "💡 Recovery: refresh CLOUDKIT_WEB_AUTH_TOKEN (or rerun `mistdemo auth-token`) and retry.")
    } catch {
      print("❌ Unexpected non-CloudKit error: \(error)")
    }
  }

  // MARK: - 404 Not Found

  /// Demonstrates 404 by querying a record type that doesn't exist in the schema.
  internal func runNotFound() async {
    printSectionHeader("404 — Not Found (unknown record type)")
    do {
      let service = try MistKitClientFactory.create(for: config)
      _ = try await service.queryRecords(recordType: Self.bogusRecordType)
      print("⚠️  Expected 404 but query returned successfully — schema may have changed.")
    } catch let error as CloudKitError {
      printCloudKitError(error, expectedStatus: 404)
      print("💡 Recovery: handle the missing record (return empty / show empty state) and continue.")
    } catch {
      print("❌ Unexpected non-CloudKit error: \(error)")
    }
  }

  // MARK: - 409 Conflict

  /// Demonstrates 409 by creating a record, modifying it once (which advances the
  /// `recordChangeTag`), then attempting a second modify with the original (now
  /// stale) tag. CloudKit returns 409 with the current `serverRecord`.
  internal func runConflict() async {
    printSectionHeader("409 — Conflict (stale recordChangeTag)")

    let service: CloudKitService
    do {
      service = try MistKitClientFactory.create(for: config)
    } catch {
      print("❌ Could not build service: \(error)")
      return
    }

    let recordName = "demo-errors-conflict-\(Int(Date().timeIntervalSince1970))"
    var createdRecordName: String?
    var staleTag: String?

    // Step 1 (setup): create the base record.
    do {
      print("\n1️⃣  Creating record \(recordName)…")
      let created = try await service.createRecord(
        recordType: Self.conflictRecordType,
        recordName: recordName,
        fields: ["title": .string("original")]
      )
      createdRecordName = created.recordName
      staleTag = created.recordChangeTag
      print("   ✅ Created. Initial recordChangeTag = \(describe(staleTag))")
    } catch {
      print("❌ Setup failed during create — cannot run 409 demo: \(error)")
      return
    }

    // Step 2 (setup): first update advances the changeTag server-side.
    do {
      print("\n2️⃣  Updating once (advances recordChangeTag server-side)…")
      let updated = try await service.updateRecord(
        recordType: Self.conflictRecordType,
        recordName: recordName,
        fields: ["title": .string("first-update")],
        recordChangeTag: staleTag
      )
      print("   ✅ Update accepted. New recordChangeTag = \(describe(updated.recordChangeTag))")
    } catch {
      print("❌ Setup failed during first update — cannot run 409 demo: \(error)")
      await cleanupConflictRecord(service: service, createdRecordName: createdRecordName)
      return
    }

    // Step 3 (the demo): re-use the now-stale changeTag.
    do {
      print("\n3️⃣  Re-using the original (now stale) recordChangeTag — expect 409…")
      _ = try await service.updateRecord(
        recordType: Self.conflictRecordType,
        recordName: recordName,
        fields: ["title": .string("second-update-stale")],
        recordChangeTag: staleTag
      )
      print("⚠️  Expected 409 but the stale-tag update was accepted.")
    } catch {
      printCloudKitError(error, expectedStatus: 409)
      if error.httpStatusCode == 409 {
        print(
          "💡 Recovery: read the `serverRecord` from the response, merge fields, and retry"
            + " with the fresh recordChangeTag.")
      }
    }

    await cleanupConflictRecord(service: service, createdRecordName: createdRecordName)
  }

  /// Best-effort delete of the record created during the 409 demo.
  private func cleanupConflictRecord(
    service: CloudKitService,
    createdRecordName: String?
  ) async {
    guard let createdRecordName else { return }
    print("\n🧹 Cleaning up demo record \(createdRecordName)…")
    do {
      try await service.deleteRecord(
        recordType: Self.conflictRecordType,
        recordName: createdRecordName
      )
      print("   ✅ Deleted.")
    } catch {
      print("   ⚠️  Cleanup failed (non-fatal): \(error)")
    }
  }

  // MARK: - Output helpers

  private func printRunnerHeader() {
    print("\n" + String(repeating: "=", count: 80))
    print("🛑 CloudKit Error Demo — typed CloudKitError handling")
    print(String(repeating: "=", count: 80))
    print("Container: \(config.containerIdentifier)")
    print("Database:  \(config.database.rawValue)")
    print(String(repeating: "=", count: 80))
  }

  private func printRunnerFooter() {
    print("\n" + String(repeating: "=", count: 80))
    print("✅ Error demo complete")
    print(String(repeating: "=", count: 80))
  }

  private func printSectionHeader(_ title: String) {
    print("\n" + String(repeating: "-", count: 80))
    print("▶ \(title)")
    print(String(repeating: "-", count: 80))
  }

  private func printCloudKitError(_ error: CloudKitError, expectedStatus: Int) {
    let status = error.httpStatusCode.map(String.init) ?? "n/a"
    let prefix = error.httpStatusCode == expectedStatus ? "✅" : "❌"
    print("\(prefix) Caught CloudKitError — status: \(status)")
    if case .httpErrorWithDetails(_, let serverErrorCode, let reason) = error {
      print("   serverErrorCode: \(serverErrorCode ?? "<none>")")
      print("   reason:          \(reason ?? "<none>")")
    } else {
      print("   detail: \(error.localizedDescription)")
    }
  }

  private func describe(_ tag: String?) -> String {
    guard let tag, !tag.isEmpty else { return "<none>" }
    return tag
  }
}

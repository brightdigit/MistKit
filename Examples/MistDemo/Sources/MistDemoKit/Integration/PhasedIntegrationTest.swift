//
//  PhasedIntegrationTest.swift
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

internal import Foundation
internal import MistKit

/// An integration test composed of an ordered list of phases.
///
/// Conformers only need to declare `name`, `database`, and `phases`; the
/// default `run(context:)` implementation drives the array, prints headers,
/// tracks completion, attempts cleanup-on-failure, and prints a summary.
internal protocol PhasedIntegrationTest: IntegrationTest {
  var phases: [any IntegrationPhase] { get }
}

extension PhasedIntegrationTest {
  internal func run(context: PhaseContext) async throws {
    printHeader(context: context)

    var state = PhaseState()
    var completed: [Int] = []
    var skipped: [Int] = []

    do {
      for (index, phase) in phases.enumerated() {
        if context.skipCleanup, phase is any CleanupPhaseMarker {
          skipped.append(index)
          continue
        }
        try await phase.runErased(context: context, state: &state)
        completed.append(index)
      }
    } catch {
      print("\n\u{274C} Error: \(error)")
      let cleanupAlreadyRan = phases.enumerated().contains { index, phase in
        phase is any CleanupPhaseMarker && completed.contains(index)
      }
      if !state.createdRecordNames.isEmpty,
        !context.skipCleanup,
        !cleanupAlreadyRan
      {
        let count = state.createdRecordNames.count
        print(
          "\n\u{26A0}\u{FE0F}  Attempting cleanup of \(count) test records..."
        )
        try? await CleanupPhase().runErased(
          context: context, state: &state
        )
      }
      printSummary(
        completed: completed, skipped: skipped, errored: true
      )
      throw error
    }

    if context.skipCleanup, !state.createdRecordNames.isEmpty {
      printSkippedCleanup(
        context: context,
        recordNames: state.createdRecordNames
      )
    }
    printSummary(
      completed: completed, skipped: skipped, errored: false
    )
  }

  // MARK: - Printing

  private func printHeader(context: PhaseContext) {
    print("\n" + String(repeating: "=", count: 80))
    print("\u{1F9EA} Integration Test Suite: \(name)")
    print(String(repeating: "=", count: 80))
    print("Container: \(context.containerIdentifier)")
    let dbLabel = database.pathSegment == "public" ? "public" : "private"
    print("Database: \(dbLabel)")
    print("Record Count: \(context.recordCount)")
    print("Asset Size: \(context.assetSizeKB) KB")
    print(String(repeating: "=", count: 80))
  }

  private func printSkippedCleanup(
    context: PhaseContext, recordNames: [String]
  ) {
    print(
      "\n\u{26A0}\u{FE0F}  Skipping cleanup (--skip-cleanup flag set)"
    )
    print("   Test records left in CloudKit:")
    for name in recordNames { print("   - \(name)") }
    print("\nTo manually cleanup these records:")
    print(
      "   1. Visit https://icloud.developer.apple.com/dashboard/"
    )
    let cid = context.containerIdentifier
    print("   2. Select your container: \(cid)")
    let dbName = database.pathSegment == "public" ? "Public" : "Private"
    print(
      "   3. Navigate to \(dbName) Database \u{2192} Records"
    )
    let recType = MistDemoConfig.recordType
    print("   4. Search for record type: \(recType)")
  }

  private func printSummary(
    completed: [Int], skipped: [Int], errored: Bool
  ) {
    print("\n" + String(repeating: "=", count: 80))
    let header =
      errored
      ? "\u{26A0}\u{FE0F}  Integration Test Failed"
      : "\u{2705} Integration Test Complete!"
    print(header)
    print(String(repeating: "=", count: 80))
    print("\nPhases:")

    let totalPhases = phases.count
    let numberWidth = String(totalPhases).count

    for (index, phase) in phases.enumerated() {
      let number = String(index + 1).leftPadded(
        toWidth: numberWidth
      )
      let phaseType = type(of: phase)
      let title = phaseType.title.rightPadded(toWidth: 28)
      let label =
        "Phase \(number): \(title)(\(phaseType.apiName))"
      let marker: String
      if completed.contains(index) {
        marker = "\u{2705}"
      } else if skipped.contains(index) {
        marker = "\u{23ED}\u{FE0F} "
      } else {
        marker = errored ? "\u{274C}" : "\u{23ED}\u{FE0F} "
      }
      print("  \(marker) \(label)")
    }

    print("\n\u{1F4A1} Next steps:")
    print("  \u{2022} Run with --verbose for detailed output")
    let tip = "  \u{2022} Use --skip-cleanup to inspect records"
    print("\(tip) in CloudKit Console")
  }
}

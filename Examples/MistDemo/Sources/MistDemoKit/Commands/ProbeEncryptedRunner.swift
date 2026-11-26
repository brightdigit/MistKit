//
//  ProbeEncryptedRunner.swift
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

/// Drives the `probe-encrypted` steps and collects one outcome per step.
internal struct ProbeEncryptedRunner {
  /// One reported line in the final summary.
  internal struct Outcome {
    internal let step: String
    internal let mark: String
    internal let detail: String
  }

  internal static let secretField = "secret"
  internal static let secretValue = "mistkit-encrypted-probe"
  internal static let assetField = "image"

  internal let service: CloudKitService
  internal let config: ProbeEncryptedConfig
  internal let zoneID: ZoneID?
  /// The encrypted probe record as most recently read back, used for the
  /// asset download step.
  internal var encryptedRecord: RecordInfo?
  internal var outcomes: [Outcome] = []

  internal var database: MistKit.Database { config.base.database }
  internal var plainRecordName: String { "\(config.recordName)-plain" }
  internal var probeRecordNames: [String] { [config.recordName, plainRecordName] }

  internal init(service: CloudKitService, config: ProbeEncryptedConfig) {
    self.service = service
    self.config = config
    self.zoneID = config.zoneName.map {
      ZoneID(zoneName: $0, ownerName: config.zoneOwner)
    }
  }

  internal mutating func run() async {
    printHeader()
    await probeZones()
    if !config.skipWrite {
      await probeWrites()
    }
    await probeLookup()
    await probeQuery()
    await probeChanges()
    await probeAssetDownload()
    if config.cleanup {
      await probeCleanup()
    }
    printSummary()
  }

  // MARK: - Step plumbing

  /// Runs `body`, printing and recording any thrown error. Returns `nil` on
  /// failure so the caller can move on to the next step.
  internal mutating func step<T>(
    _ name: String,
    _ body: () async throws -> T
  ) async -> T? {
    print("\n▶ \(name)")
    do {
      return try await body()
    } catch {
      fail(name, Self.describe(error))
      return nil
    }
  }

  internal mutating func pass(_ step: String, _ detail: String) {
    note(step, mark: "✅", detail)
  }

  internal mutating func fail(_ step: String, _ detail: String) {
    note(step, mark: "❌", detail)
  }

  internal mutating func skip(_ step: String, _ detail: String) {
    print("\n▶ \(step)")
    note(step, mark: "⏭️ ", detail)
  }

  private mutating func note(_ step: String, mark: String, _ detail: String) {
    print("   \(mark) \(detail)")
    outcomes.append(Outcome(step: step, mark: mark, detail: detail))
  }

  // MARK: - Printing

  private func printHeader() {
    print("\n" + String(repeating: "=", count: 80))
    print("🔐 Encrypted Field Probe (issue #392)")
    print(String(repeating: "=", count: 80))
    print("Container: \(config.base.containerIdentifier)")
    print("Environment: \(config.base.environment)")
    print("Database: \(database.pathSegment)")
    print("Zone: \(config.zoneName ?? "_defaultZone")")
    print("Records: \(probeRecordNames.joined(separator: ", "))")
    let mode = config.skipWrite ? "read-only" : "write + read"
    print("Mode: \(mode)\(config.cleanup ? " + cleanup" : "")")
    print(String(repeating: "=", count: 80))
  }

  private func printSummary() {
    print("\n" + String(repeating: "=", count: 80))
    print("📋 Probe summary — copy into issue #392")
    print(String(repeating: "=", count: 80))
    for outcome in outcomes {
      print("\(outcome.mark) \(outcome.step): \(outcome.detail)")
    }
    print(String(repeating: "=", count: 80))
  }
}

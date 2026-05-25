//
//  ProbeDuplicateSubscriptionCommand.swift
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

/// One-off diagnostic command: probes CloudKit's
/// `subscriptions/modify` to pin down what triggers the
/// `INTERNAL_ERROR` / "could not find subscription we just created"
/// failure. Not part of the integration test suite — run manually.
public struct ProbeDuplicateSubscriptionCommand: MistDemoCommand {
  /// The configuration type.
  public typealias Config = ProbeDuplicateSubscriptionConfig
  /// The command name.
  public static let commandName = "probe-duplicate-subscription"
  /// The command abstract.
  public static let abstract =
    "Probe CloudKit subscription uniqueness (diagnostic)"
  /// The command help text.
  public static let helpText = """
    PROBE-DUPLICATE-SUBSCRIPTION - Diagnostic: which axes trigger duplicate?

    Creates a seed subscription, then tries variations to identify which
    properties (subscriptionID vs query+firesOn vs recordType) CloudKit
    treats as uniqueness keys. Prints raw serverErrorCode / reason for
    every probe so we can confirm or refute MistKit's "isLikelyDuplicate"
    detection. Cleans up all subscriptions it creates.

    USAGE:
      mistdemo probe-duplicate-subscription [options]

    OPTIONS:
      --database <type>              public | private | shared
      --record-type <type>           Record type to probe (default: Note)
      --alternate-record-type <type> Record type for negative control
                                     (default: Article)
      --verbose                      Print full SubscriptionResult per probe

    EXAMPLES:
      mistdemo probe-duplicate-subscription --database public --verbose
      mistdemo probe-duplicate-subscription --database private
    """

  private let config: ProbeDuplicateSubscriptionConfig

  /// Creates a new instance.
  public init(config: ProbeDuplicateSubscriptionConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    let service = try MistKitClientFactory.create(for: config.base)
    let database = config.base.database
    let probeRun = UUID().uuidString.lowercased().prefix(8)

    print("🧪 probe-duplicate-subscription (run=\(probeRun))")
    print("   database=\(database.pathSegment) recordType=\(config.recordType)")
    print(
      "   Each experiment: seed one subscription, probe with a variation, "
      + "report seed/probe outcomes, cleanup."
    )

    let experiments = Self.makeExperiments(
      run: probeRun,
      recordType: config.recordType,
      alternateRecordType: config.alternateRecordType
    )

    var summary: [(Int, String, String)] = []
    for experiment in experiments {
      let outcome = await runExperiment(
        experiment,
        service: service,
        database: database
      )
      summary.append((experiment.index, experiment.label, outcome))
    }

    print("")
    print("📋 Summary")
    for (index, label, outcome) in summary {
      print("   #\(index) \(label)")
      print("       → \(outcome)")
    }
  }

  private static func makeExperiments(
    run: Substring,
    recordType: String,
    alternateRecordType: String
  ) -> [ProbeExperiment] {
    [
      .same(
        index: 1,
        label: "different ID, same recordType, same firesOn",
        run: run,
        recordType: recordType,
        seedFiresOn: [.create],
        probeFiresOn: [.create],
        sameID: false
      ),
      .same(
        index: 2,
        label: "same ID, same recordType, same firesOn",
        run: run,
        recordType: recordType,
        seedFiresOn: [.create],
        probeFiresOn: [.create],
        sameID: true
      ),
      .same(
        index: 3,
        label: "different ID, same recordType, different firesOn",
        run: run,
        recordType: recordType,
        seedFiresOn: [.create],
        probeFiresOn: [.update],
        sameID: false
      ),
      .same(
        index: 4,
        label: "different ID, same recordType, superset firesOn",
        run: run,
        recordType: recordType,
        seedFiresOn: [.create],
        probeFiresOn: [.create, .update],
        sameID: false
      ),
      .differentRecordType(
        index: 5,
        label: "different ID, different recordType, same firesOn",
        run: run,
        seedRecordType: recordType,
        probeRecordType: alternateRecordType,
        firesOn: [.create]
      ),
    ]
  }

  private func runExperiment(
    _ experiment: ProbeExperiment,
    service: CloudKitService,
    database: Database
  ) async -> String {
    let seedSub = experiment.seedSubscription()
    let probeSub = experiment.probeSubscription()
    print("")
    print("▶︎ #\(experiment.index): \(experiment.label)")
    print(
      "   seed:  id=\(seedSub.subscriptionID) "
      + describeSubscription(seedSub)
    )
    print(
      "   probe: id=\(probeSub.subscriptionID) "
      + describeSubscription(probeSub)
    )

    // Seed
    let seedResult: SubscriptionResult?
    do {
      let seedResults = try await service.modifySubscriptions(
        [.create(seedSub)],
        database: database
      )
      seedResult = seedResults.first
      print("   seed result:  \(formatResult(seedResults.first))")
    } catch {
      print("   seed result:  THREW \(error)")
      return "seed threw — cannot probe"
    }

    var probeOutcome = "no probe result"
    do {
      let probeResults = try await service.modifySubscriptions(
        [.create(probeSub)],
        database: database
      )
      print("   probe result: \(formatResult(probeResults.first))")
      probeOutcome = summarize(probeResults.first)
    } catch {
      print("   probe result: THREW \(error)")
      probeOutcome = "threw: \(error)"
    }

    // Cleanup — best-effort, both IDs in case seed succeeded.
    var idsToDelete: [String] = [seedSub.subscriptionID]
    if probeSub.subscriptionID != seedSub.subscriptionID {
      idsToDelete.append(probeSub.subscriptionID)
    }
    for id in idsToDelete {
      do {
        try await service.deleteSubscription(id: id, database: database)
      } catch {
        print("   cleanup warning for '\(id)': \(error)")
      }
    }
    _ = seedResult
    return probeOutcome
  }

  private func describeSubscription(_ sub: SubscriptionInfo) -> String {
    let recordType = sub.query?.recordType ?? "<nil>"
    var names: [String] = []
    if sub.firesOn.contains(.create) { names.append("create") }
    if sub.firesOn.contains(.update) { names.append("update") }
    if sub.firesOn.contains(.delete) { names.append("delete") }
    return "recordType=\(recordType) firesOn=[\(names.joined(separator: ","))]"
  }

  private func formatResult(_ result: SubscriptionResult?) -> String {
    guard let result else {
      return "nil"
    }
    switch result {
    case .success(let info):
      return "SUCCESS id=\(info.subscriptionID)"
    case .failure(let failure):
      var parts: [String] = [
        "FAILURE id=\(failure.identifier)",
        "code=\(failure.serverErrorCode.rawValue)",
        "reason=\"\(failure.reason ?? "")\"",
        "isLikelyDuplicate=\(failure.isLikelyDuplicate)",
      ]
      if config.verbose, let uuid = failure.uuid {
        parts.append("uuid=\(uuid)")
      }
      return parts.joined(separator: " ")
    }
  }

  private func summarize(_ result: SubscriptionResult?) -> String {
    switch result {
    case .none:
      return "no result"
    case .success:
      return "SUCCESS"
    case .failure(let failure):
      return
        "FAIL code=\(failure.serverErrorCode.rawValue) "
        + "isLikelyDuplicate=\(failure.isLikelyDuplicate)"
    }
  }
}

// `ProbeExperiment` and `ProbeSubscriptionTemplate` live in
// `ProbeExperiment.swift`.

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

// `helpText` below is a multi-line string whose option column doesn't
// align with Swift's indent steps; the rule isn't useful inside literal
// help text.
// swiftlint:disable indentation_width

/// One-off diagnostic command: probes CloudKit's
/// `subscriptions/modify` to pin down what triggers the
/// `INTERNAL_ERROR` / "could not find subscription we just created"
/// failure. Not part of the integration test suite — run manually.
public struct ProbeDuplicateSubscriptionCommand: MistDemoCommand {
  /// The configuration type.
  public typealias Config = ProbeDuplicateSubscriptionConfig

  /// One row of the end-of-run summary printed by ``execute()``.
  internal struct ExperimentOutcome {
    internal let index: Int
    internal let label: String
    internal let result: String
  }

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

  internal static func makeExperiments(
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

    var summary: [ExperimentOutcome] = []
    for experiment in experiments {
      let outcome = await runExperiment(
        experiment,
        service: service,
        database: database
      )
      summary.append(
        ExperimentOutcome(
          index: experiment.index,
          label: experiment.label,
          result: outcome
        )
      )
    }

    print("")
    print("📋 Summary")
    for row in summary {
      print("   #\(row.index) \(row.label)")
      print("       → \(row.result)")
    }
  }

  internal func formatResult(_ result: SubscriptionResult?) -> String {
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
}

// swiftlint:enable indentation_width

// The per-experiment runner lives in
// `ProbeDuplicateSubscriptionCommand+Experiment.swift`;
// `ProbeExperiment` lives in `ProbeExperiment.swift` and
// `ProbeSubscriptionTemplate` in its own file.

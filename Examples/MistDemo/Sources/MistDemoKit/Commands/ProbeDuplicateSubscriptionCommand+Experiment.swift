//
//  ProbeDuplicateSubscriptionCommand+Experiment.swift
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

extension ProbeDuplicateSubscriptionCommand {
  internal func runExperiment(
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

    // Best-effort cleanup, both IDs in case seed succeeded.
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

  internal func describeSubscription(_ sub: SubscriptionInfo) -> String {
    let recordType = sub.query?.recordType ?? "<nil>"
    var names: [String] = []
    if sub.firesOn.contains(.create) {
      names.append("create")
    }
    if sub.firesOn.contains(.update) {
      names.append("update")
    }
    if sub.firesOn.contains(.delete) {
      names.append("delete")
    }
    return "recordType=\(recordType) firesOn=[\(names.joined(separator: ","))]"
  }

  internal func summarize(_ result: SubscriptionResult?) -> String {
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

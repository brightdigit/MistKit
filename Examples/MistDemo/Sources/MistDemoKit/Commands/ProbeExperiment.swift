//
//  ProbeExperiment.swift
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

internal import MistKit

/// One probe experiment — a seed subscription + a probe subscription
/// + a label. Both are pure value types; we materialize them via
/// `seedSubscription()` / `probeSubscription()` so identifiers stay
/// stable across the seed/probe/cleanup phases of one experiment.
internal struct ProbeExperiment {
  internal let index: Int
  internal let label: String
  internal let seed: ProbeSubscriptionTemplate
  internal let probe: ProbeSubscriptionTemplate

  internal static func same(
    index: Int,
    label: String,
    run: Substring,
    recordType: String,
    seedFiresOn: SubscriptionFireEvents,
    probeFiresOn: SubscriptionFireEvents,
    sameID: Bool
  ) -> ProbeExperiment {
    let seedID = "probe-\(run)-e\(index)-seed"
    let probeID = sameID ? seedID : "probe-\(run)-e\(index)-probe"
    return ProbeExperiment(
      index: index,
      label: label,
      seed: ProbeSubscriptionTemplate(
        id: seedID,
        recordType: recordType,
        firesOn: seedFiresOn
      ),
      probe: ProbeSubscriptionTemplate(
        id: probeID,
        recordType: recordType,
        firesOn: probeFiresOn
      )
    )
  }

  internal static func differentRecordType(
    index: Int,
    label: String,
    run: Substring,
    seedRecordType: String,
    probeRecordType: String,
    firesOn: SubscriptionFireEvents
  ) -> ProbeExperiment {
    ProbeExperiment(
      index: index,
      label: label,
      seed: ProbeSubscriptionTemplate(
        id: "probe-\(run)-e\(index)-seed",
        recordType: seedRecordType,
        firesOn: firesOn
      ),
      probe: ProbeSubscriptionTemplate(
        id: "probe-\(run)-e\(index)-probe",
        recordType: probeRecordType,
        firesOn: firesOn
      )
    )
  }

  internal func seedSubscription() -> SubscriptionInfo {
    seed.materialize()
  }

  internal func probeSubscription() -> SubscriptionInfo {
    probe.materialize()
  }
}

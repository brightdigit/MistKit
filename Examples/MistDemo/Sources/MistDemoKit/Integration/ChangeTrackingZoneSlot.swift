//
//  ChangeTrackingZoneSlot.swift
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

/// A custom zone plus records written for `changes/zone` integration phases.
///
/// CloudKit rejects change tracking in `_defaultZone`; phases thread this slot
/// through ``PhaseState`` so ``FetchAllRecordZoneChangesPhase`` can tear the
/// zone down after exercising auto-pagination.
internal struct ChangeTrackingZoneSlot: PhaseStateDecodable,
  PhaseStateEncodable, Sendable
{
  internal let zoneID: ZoneID
  internal let recordNames: [String]

  internal init(zoneID: ZoneID, recordNames: [String]) {
    self.zoneID = zoneID
    self.recordNames = recordNames
  }

  internal init(from state: PhaseState) throws {
    guard let slot = state.changeTrackingZone else {
      throw IntegrationTestError.missingPhaseState("changeTrackingZone")
    }
    self = slot
  }

  internal func encode(to state: inout PhaseState) {
    state.changeTrackingZone = self
  }
}

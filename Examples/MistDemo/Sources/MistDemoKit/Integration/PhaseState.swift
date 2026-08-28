//
//  PhaseState.swift
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

/// Mutable state that flows between phases as the test progresses.
///
/// Each phase reads the slice it needs by initializing its `Input` type
/// via `PhaseStateDecodable.init(from:)` and writes its results back
/// through `PhaseStateEncodable.encode(to:)`. The runner threads a single
/// `PhaseState` value through the pipeline via
/// `IntegrationPhase.runErased(context:state:)`.
internal struct PhaseState: Sendable {
  internal var assetReceipt: AssetUploadReceipt?
  internal var createdRecordNames: [String] = []
  internal var syncToken: String?
  internal var currentUser: UserInfo?
  /// Custom zone provisioned by ``FetchRecordZoneChangesPhase`` for
  /// ``FetchAllRecordZoneChangesPhase`` to exercise and tear down.
  internal var changeTrackingZone: ChangeTrackingZoneSlot?
}

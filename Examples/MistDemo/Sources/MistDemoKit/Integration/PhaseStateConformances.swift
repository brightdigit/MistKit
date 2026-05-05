//
//  PhaseStateConformances.swift
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

/// Sentinel used as `Input` or `Output` when a phase consumes or produces
/// no `PhaseState`. Stands in for `Void`, which can't conform to protocols.
struct NoState: PhaseStateDecodable, PhaseStateEncodable {
  init() {}
  init(from state: PhaseState) throws {}
  func encode(to state: inout PhaseState) {}
}

/// Wraps the `createdRecordNames` slot of `PhaseState`.
struct CreatedRecordNames: PhaseStateDecodable, PhaseStateEncodable {
  let names: [String]

  init(_ names: [String]) {
    self.names = names
  }

  init(from state: PhaseState) throws {
    self.names = state.createdRecordNames
  }

  func encode(to state: inout PhaseState) {
    state.createdRecordNames = names
  }
}

/// Wraps the `syncToken` slot of `PhaseState`.
struct SyncTokenSlot: PhaseStateDecodable, PhaseStateEncodable {
  let value: String?

  init(_ value: String?) {
    self.value = value
  }

  init(from state: PhaseState) throws {
    self.value = state.syncToken
  }

  func encode(to state: inout PhaseState) {
    state.syncToken = value
  }
}

/// Composite input read by `IncrementalSyncPhase`.
struct IncrementalSyncInput: PhaseStateDecodable {
  let syncToken: String?
  let recordNames: [String]

  init(from state: PhaseState) throws {
    self.syncToken = state.syncToken
    self.recordNames = state.createdRecordNames
  }
}

extension AssetUploadReceipt: PhaseStateDecodable, PhaseStateEncodable {
  init(from state: PhaseState) throws {
    guard let receipt = state.assetReceipt else {
      throw IntegrationTestError.missingPhaseState("assetReceipt")
    }
    self = receipt
  }

  func encode(to state: inout PhaseState) {
    state.assetReceipt = self
  }
}

extension UserInfo: PhaseStateDecodable, PhaseStateEncodable {
  init(from state: PhaseState) throws {
    guard let user = state.currentUser else {
      throw IntegrationTestError.missingPhaseState("currentUser")
    }
    self = user
  }

  func encode(to state: inout PhaseState) {
    state.currentUser = self
  }
}

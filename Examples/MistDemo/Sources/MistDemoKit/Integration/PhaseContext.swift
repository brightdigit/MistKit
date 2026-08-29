//
//  PhaseContext.swift
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

/// Shared dependencies and configuration available to every phase.
internal struct PhaseContext: Sendable {
  internal let service: CloudKitService
  internal let containerIdentifier: String
  internal let database: MistKit.Database
  internal let recordCount: Int
  internal let assetSizeKB: Int
  internal let skipCleanup: Bool
  internal let verbose: Bool
  /// Optional email address used by `LookupUsersByEmailPhase` to exercise
  /// `users/lookup/email` against a known-discoverable iCloud account. When
  /// nil, the phase falls back to the caller's own email (often unavailable)
  /// and skips otherwise.
  internal let lookupEmail: String?
  /// Optional share short GUID used by `ResolveRecordsPhase` and
  /// `AcceptSharesPhase` to exercise `records/resolve` / `records/accept`
  /// against a known share. There is no way to mint a short GUID from
  /// within the public pipeline — it must come from a share created out of
  /// band — so both phases skip when this is `nil`. The private pipeline
  /// instead uses ``shareeService`` + ``shareeEmail`` to create and accept.
  internal let shareShortGUID: String?
  /// Service authenticated as the **sharee** (same API token / container,
  /// `CLOUDKIT_SHAREE_WEB_AUTH_TOKEN`). Required by
  /// `ShareCreateAndAcceptPhase` together with ``shareeEmail``: creates a
  /// share as the sharer (`service`) and accepts it as this sharee.
  /// `nil` only for pipelines that omit that phase (e.g. public).
  internal let shareeService: CloudKitService?
  /// iCloud email of the sharee (`CLOUDKIT_SHAREE_EMAIL`), used as the
  /// invite lookup info when creating the share. Required with
  /// ``shareeService`` for the private share phase.
  internal let shareeEmail: String?
}

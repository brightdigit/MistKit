//
//  AcceptSharesPhase.swift
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

/// Calls POST `records/accept`.
///
/// Like `ResolveRecordsPhase`, prefers the short GUID supplied via
/// `PhaseContext.shareShortGUID` (`--share-short-guid` /
/// `CLOUDKIT_SHARE_SHORT_GUID`) and skips (non-fatally) when it isn't
/// configured. Accepting an already-accepted share fails the request, so
/// this phase is only useful against a freshly-invited fixture share.
internal struct AcceptSharesPhase: IntegrationPhase {
  internal typealias Input = NoState
  internal typealias Output = NoState

  internal static let title = "Accept shares"
  internal static let emoji = "🤝"
  internal static let apiName = "acceptShares"

  internal func run(input: NoState, context: PhaseContext) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    guard let shortGUID = context.shareShortGUID, !shortGUID.isEmpty else {
      print(
        """
        ⏭️  Skipping — no share short GUID available. Set \
        --share-short-guid or CLOUDKIT_SHARE_SHORT_GUID to exercise \
        this phase.
        """
      )
      return NoState()
    }

    let results = try await context.service.acceptShares([
      ShortGUID(value: shortGUID)
    ])

    print(
      "✅ Accepted \(results.count) share\(results.count == 1 ? "" : "s")"
    )

    if context.verbose {
      for result in results {
        print("   Root record: \(result.rootRecordName ?? "-")")
        print("   Participant status: \(result.participantStatus?.rawValue ?? "-")")
      }
    }

    return NoState()
  }
}

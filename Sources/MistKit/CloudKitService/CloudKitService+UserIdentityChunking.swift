//
//  CloudKitService+UserIdentityChunking.swift
//  MistKit
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

extension CloudKitService {
  /// Discover user identities for the given lookup infos, automatically
  /// chunking large inputs.
  ///
  /// Convenience over ``discoverUserIdentities(lookupInfos:)`` that splits
  /// `lookupInfos` into batches of at most `batchSize` (CloudKit caps a single
  /// `users/discover` request at ``maxRecordsPerRequest`` infos) and
  /// concatenates the per-batch identities in input order.
  ///
  /// - Note: This overloads the (input-less) address-book discovery
  ///   `discoverAllUserIdentities()` — *this* form discovers identities matching
  ///   the supplied `lookupInfos` via the batched POST `users/discover`
  ///   endpoint, whereas the no-argument form enumerates the caller's address
  ///   book via GET.
  ///
  /// - Parameters:
  ///   - lookupInfos: Email/phone/record-name lookups to resolve (any length).
  ///   - batchSize: Maximum infos per request, clamped to
  ///     `1...maxRecordsPerRequest` (defaults to ``maxRecordsPerRequest``).
  /// - Returns: The resolved identities across all batches, in input order.
  /// - Throws: `CloudKitError` if any batch fails.
  public func discoverAllUserIdentities(
    lookupInfos: [UserIdentityLookupInfo],
    batchSize: Int = CloudKitService.maxRecordsPerRequest
  ) async throws(CloudKitError) -> [UserIdentity] {
    try await chunkedBatches(
      lookupInfos,
      batchSize: batchSize,
      context: "discoverAllUserIdentities"
    ) { batch throws(CloudKitError) in
      try await self.discoverUserIdentities(lookupInfos: batch)
    }
  }
}

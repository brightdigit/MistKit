//
//  CloudKitService+LookupAllRecords.swift
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
  /// Look up records by name, automatically chunking large inputs.
  ///
  /// Convenience over ``lookupRecords(recordNames:desiredKeys:database:)`` that
  /// splits `recordNames` into batches of at most `batchSize` (CloudKit caps a
  /// single lookup request at ``maxRecordsPerRequest`` records) and concatenates
  /// the per-batch results in input order. Use this whenever the number of
  /// record names may exceed 200; the bare primitive sends them all in one
  /// request and CloudKit rejects more than 200 with `BAD_REQUEST`.
  ///
  /// - Parameters:
  ///   - recordNames: Record names to fetch (any length).
  ///   - desiredKeys: Optional array of field names to fetch.
  ///   - database: The CloudKit database scope to read from
  ///     (`.public`, `.private`, `.shared`).
  ///   - batchSize: Maximum record names per request, clamped to
  ///     `1...maxRecordsPerRequest` (defaults to ``maxRecordsPerRequest``).
  /// - Returns: A ``RecordResult`` per requested record, in the same order as
  ///   `recordNames` — `.success` for a found record, `.failure` (e.g.
  ///   `NOT_FOUND`) for one CloudKit could not return.
  /// - Throws: `CloudKitError` if any batch fails.
  public func lookupAllRecords(
    recordNames: [RecordName],
    desiredKeys: [String]? = nil,
    database: Database,
    batchSize: Int = CloudKitService.maxRecordsPerRequest
  ) async throws(CloudKitError) -> [RecordResult] {
    try await chunkedBatches(
      recordNames,
      batchSize: batchSize,
      context: "lookupAllRecords"
    ) { batch throws(CloudKitError) in
      try await self.lookupRecords(
        recordNames: batch,
        desiredKeys: desiredKeys,
        database: database
      )
    }
  }
}

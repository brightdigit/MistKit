//
//  CloudKitService+BatchChunking.swift
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
  /// Split `items` into batches of at most `batchSize`, invoke `perBatch`
  /// for each batch in order, and concatenate the results.
  ///
  /// This is the shared engine behind the auto-chunking convenience methods
  /// (`lookupAllRecords`, `discoverAllUserIdentities(lookupInfos:)`, etc.) that
  /// sit on top of CloudKit's single-request batch primitives. CloudKit caps
  /// most batch endpoints at ``maxRecordsPerRequest`` items per request, so a
  /// caller with a larger input must split it across multiple requests.
  ///
  /// Unlike server-driven pagination, the number of batches here is fully
  /// determined up front (`ceil(items.count / batchSize)`), so there is no
  /// runaway-loop risk and therefore no `maxPages`-style ceiling that throws —
  /// `batchSize` is the only knob, clamped to `1...maxRecordsPerRequest`.
  ///
  /// - Parameters:
  ///   - items: The full input to process; an empty input issues no requests.
  ///   - batchSize: Maximum items per batch, clamped to
  ///     `1...maxRecordsPerRequest`.
  ///   - context: Operation label used when mapping cancellation to
  ///     `CloudKitError`.
  ///   - perBatch: Performs one batch (a single CloudKit request) and returns
  ///     that batch's results.
  /// - Returns: Every batch's results concatenated in input order.
  internal func chunkedBatches<Input, Output>(
    _ items: [Input],
    batchSize: Int,
    context: String,
    _ perBatch: ([Input]) async throws(CloudKitError) -> [Output]
  ) async throws(CloudKitError) -> [Output] {
    guard !items.isEmpty else {
      return []
    }

    let size = min(max(batchSize, 1), CloudKitService.maxRecordsPerRequest)
    var results: [Output] = []
    var index = 0

    while index < items.count {
      do {
        try Task.checkCancellation()
      } catch {
        throw mapToCloudKitError(error, context: context)
      }

      let end = min(index + size, items.count)
      results.append(contentsOf: try await perBatch(Array(items[index..<end])))
      index = end
    }

    return results
  }
}

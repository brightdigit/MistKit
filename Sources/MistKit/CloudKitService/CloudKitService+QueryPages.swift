//
//  CloudKitService+QueryPages.swift
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

internal import Foundation

extension CloudKitService {
  /// Query records one page at a time, as an async stream of pages.
  ///
  /// Each element is one `records/query` response, in order; the stream
  /// finishes after the page whose ``QueryResult/continuationMarker`` is `nil`.
  /// Use it when the caller wants each page as it arrives (progress, counting,
  /// streaming into a table) rather than everything at once
  /// (``queryAllRecords(recordType:filters:sortBy:pageSize:desiredKeys:maxPages:zoneID:database:)``)
  /// or one page by hand
  /// (``queryRecords(_:limit:desiredKeys:continuationMarker:zoneID:zoneWide:numbersAsStrings:database:)``).
  ///
  /// It stops when the server answers with the continuation marker it was
  /// sent (the stuck-marker case), since the next request would be identical:
  /// a page with no records ends the stream before it, and a page with records
  /// is yielded once and then ends it. Unlike `queryAllRecords` there is no
  /// `maxPages` ceiling; cancel the consuming task to stop earlier.
  ///
  /// Cancelling the consuming task, or dropping the stream, cancels the
  /// request in flight and sends no more. An error ends the stream with that
  /// ``CloudKitError``; MistKit never retries. To resume after an error, start
  /// a new stream at the last page's continuation marker.
  ///
  /// - Parameters:
  ///   - query: The query to run.
  ///   - limit: Records per page (1-200, defaults to `defaultQueryLimit`).
  ///   - desiredKeys: Field names to fetch; `[]` fetches none.
  ///   - continuationMarker: Where to start; `nil` for the first page.
  ///   - zoneID: The zone to query; `nil` for the default zone.
  ///   - database: The database to query.
  /// - Returns: A stream of pages. Every error it ends with is a
  ///   ``CloudKitError``; the stream's failure type is `any Error` only
  ///   because `AsyncThrowingStream` can't carry a typed failure.
  public func queryRecordPages(
    _ query: Query,
    limit: Int? = nil,
    desiredKeys: [String]? = nil,
    continuationMarker: String? = nil,
    zoneID: ZoneID? = nil,
    database: Database
  ) -> AsyncThrowingStream<QueryResult, any Error> {
    let (stream, continuation) = AsyncThrowingStream.makeStream(
      of: QueryResult.self,
      throwing: (any Error).self
    )
    let task = Task { [self] in
      var marker = continuationMarker
      do {
        repeat {
          do {
            try Task.checkCancellation()
          } catch {
            throw mapToCloudKitError(error, context: "queryRecordPages")
          }
          let page = try await queryRecords(
            query,
            limit: limit,
            desiredKeys: desiredKeys,
            continuationMarker: marker,
            zoneID: zoneID,
            database: database
          )
          // A repeated marker means the next request would be identical, so
          // stop: before an empty page, after one with records.
          let isStuck = page.continuationMarker != nil && page.continuationMarker == marker
          if isStuck, page.records.isEmpty {
            break
          }
          continuation.yield(page)
          if isStuck {
            break
          }
          marker = page.continuationMarker
        } while marker != nil
        continuation.finish()
      } catch {
        continuation.finish(throwing: error)
      }
    }
    continuation.onTermination = { _ in task.cancel() }
    return stream
  }
}

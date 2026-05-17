//
//  QueryResult.swift
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

/// Result from querying records
///
/// Contains the matching records along with an optional continuation marker
/// for fetching the next page of results.
internal import MistKitOpenAPI

public struct QueryResult: Codable, Sendable {
  /// Records matching the query
  public let records: [RecordInfo]
  /// Marker to pass into the next query request to fetch the next page
  public let continuationMarker: String?

  /// Initialize a query result
  public init(
    records: [RecordInfo],
    continuationMarker: String?
  ) {
    self.records = records
    self.continuationMarker = continuationMarker
  }

  internal init(from response: Components.Schemas.QueryResponse) {
    self.records = response.records?.compactMap { RecordInfo(from: $0) } ?? []
    self.continuationMarker = response.continuationMarker
  }
}

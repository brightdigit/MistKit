//
//  RecordChangesResult.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

public import Foundation

/// Result from fetching record changes
///
/// Contains records that have changed since the provided sync token,
/// along with a new sync token for subsequent fetches.
public struct RecordChangesResult: Sendable {
  /// Records that have changed (created, updated, or deleted)
  public let records: [RecordInfo]
  /// Token to use for next fetch to get incremental changes
  public let syncToken: String?
  /// Whether more changes are available (for large change sets)
  public let moreComing: Bool

  /// Initialize a record changes result
  public init(
    records: [RecordInfo],
    syncToken: String?,
    moreComing: Bool
  ) {
    self.records = records
    self.syncToken = syncToken
    self.moreComing = moreComing
  }

  internal init(from response: Components.Schemas.ChangesResponse) {
    self.records = response.records?.compactMap { RecordInfo(from: $0) } ?? []
    self.syncToken = response.syncToken
    self.moreComing = response.moreComing ?? false
  }
}

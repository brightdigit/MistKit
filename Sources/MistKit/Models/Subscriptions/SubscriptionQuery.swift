//
//  SubscriptionQuery.swift
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

internal import MistKitOpenAPI

/// The query a `query`-type subscription watches.
///
/// This reuses the exact same query model as a record query — a `recordType`
/// plus the same ``QueryFilter`` / ``QuerySort`` building blocks — so a
/// subscription's predicate is expressed identically to a one-off query passed
/// to `CloudKitService.queryRecords`.
public struct SubscriptionQuery: Codable, Sendable {
  // MARK: - Internal

  internal let schema: Components.Schemas.Query

  // MARK: - Public

  /// The record type this query watches, as returned by CloudKit.
  public var recordType: String? {
    self.schema.recordType
  }

  // MARK: - Lifecycle

  internal init(_ schema: Components.Schemas.Query) {
    self.schema = schema
  }

  /// Build a subscription query.
  /// - Parameters:
  ///   - recordType: The record type the subscription watches.
  ///   - filters: Optional predicate filters (reusing ``QueryFilter``).
  ///   - sortBy: Optional sort descriptors (reusing ``QuerySort``).
  public init(
    recordType: String,
    filters: [QueryFilter] = [],
    sortBy: [QuerySort] = []
  ) {
    self.schema = Components.Schemas.Query(
      recordType: recordType,
      filterBy: filters.isEmpty ? nil : filters.map(\.filter),
      sortBy: sortBy.isEmpty ? nil : sortBy.map(\.sort)
    )
  }

  public init(from decoder: any Decoder) throws {
    self.schema = try Components.Schemas.Query(from: decoder)
  }

  public func encode(to encoder: any Encoder) throws {
    try self.schema.encode(to: encoder)
  }
}

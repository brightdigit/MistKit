//
//  Query.swift
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

/// A CloudKit query — a `recordType` plus optional ``QueryFilter``
/// predicates and ``QuerySort`` descriptors.
///
/// The same value can be passed to ``CloudKitService/queryRecords`` for a
/// one-off query and embedded in
/// ``SubscriptionInfo/Kind/query(_:)`` to describe a query
/// subscription's predicate — they share this single representation.
public struct Query: Codable, Sendable {
  // MARK: - Internal

  internal let schema: Components.Schemas.Query

  // MARK: - Public

  /// The record type this query targets, as serialized to CloudKit.
  public var recordType: String? {
    self.schema.recordType
  }

  // MARK: - Lifecycle

  internal init(_ schema: Components.Schemas.Query) {
    self.schema = schema
  }

  /// Build a CloudKit query.
  /// - Parameters:
  ///   - recordType: The record type this query targets.
  ///   - filters: Optional predicate filters (``QueryFilter``).
  ///   - sortBy: Optional sort descriptors (``QuerySort``).
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

  /// Decodes a query from the CloudKit wire format.
  public init(from decoder: any Decoder) throws {
    self.schema = try Components.Schemas.Query(from: decoder)
  }

  /// Encodes the query to the CloudKit wire format.
  public func encode(to encoder: any Encoder) throws {
    try self.schema.encode(to: encoder)
  }
}

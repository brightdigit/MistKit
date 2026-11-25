//
//  QueryDescriptor.swift
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

/// An editable description of a CloudKit query: what to fetch, how to filter
/// and sort it, and how much of it to return.
///
/// Unlike ``Query``, which is the wire form CloudKit receives, a descriptor
/// keeps each part as plain values you can inspect, edit, compare, validate
/// against a ``CloudKitSchema`` and save (`Codable`). Convert it with
/// ``query()`` and pass it, with ``limit``, ``desiredKeys`` and ``zoneID``,
/// to ``CloudKitService``'s `queryRecords`.
///
/// Conditions are combined with AND; CloudKit queries have no OR or NOT.
/// ``QueryPredicate`` reads and writes the conditions as an NSPredicate format
/// string, the syntax `CKQuery` uses.
public struct QueryDescriptor: Hashable, Codable, Sendable {
  /// The system field CloudKit matches record names on.
  ///
  /// A condition on this field may compare with a `STRING` record name or a
  /// `REFERENCE`; strings are sent as references, as CloudKit requires.
  public static let recordIDFieldName = "___recordID"

  /// The record type to query.
  public var recordType: String
  /// The zone to query.
  public var zoneID: ZoneID
  /// The conditions, combined with AND, in order.
  public var conditions: [Condition]
  /// The sorts, most significant first.
  public var sorts: [Sort]
  /// The fields to return; `nil` returns every field.
  public var desiredKeys: [String]?
  /// The number of records per page, at most
  /// ``CloudKitService/maxRecordsPerRequest``.
  public var limit: Int

  /// Creates a query description.
  /// - Parameters:
  ///   - recordType: The record type to query.
  ///   - zoneID: The zone to query; the default zone unless given.
  ///   - conditions: The conditions, combined with AND.
  ///   - sorts: The sorts, most significant first.
  ///   - desiredKeys: The fields to return; `nil` returns every field.
  ///   - limit: The number of records per page.
  public init(
    recordType: String,
    zoneID: ZoneID = .defaultZone,
    conditions: [Condition] = [],
    sorts: [Sort] = [],
    desiredKeys: [String]? = nil,
    limit: Int = CloudKitService.maxRecordsPerRequest
  ) {
    self.recordType = recordType
    self.zoneID = zoneID
    self.conditions = conditions
    self.sorts = sorts
    self.desiredKeys = desiredKeys
    self.limit = limit
  }
}

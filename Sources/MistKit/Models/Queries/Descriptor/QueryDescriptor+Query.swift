//
//  QueryDescriptor+Query.swift
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

extension QueryDescriptor {
  /// The query CloudKit receives: the record type, a filter per condition (in
  /// order) and the sorts.
  ///
  /// Pass ``limit``, ``desiredKeys`` and ``zoneID`` alongside it to
  /// ``CloudKitService``'s `queryRecords`.
  /// - Throws: ``QueryDescriptorError`` for a condition whose value doesn't fit
  ///   its comparator.
  public func query() throws(QueryDescriptorError) -> Query {
    var filters: [QueryFilter] = []
    for condition in conditions {
      filters.append(try condition.filter())
    }
    return Query(recordType: recordType, filters: filters, sortBy: sorts.map(\.querySort))
  }
}

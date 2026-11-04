//
//  QueryFilterNearAndRecordNameTests.swift
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
internal import MistKitOpenAPI
internal import Testing

@testable import MistKit

/// NEAR, record-name filters and the per-type comparator list (MistKit #490, #498).
@Suite("QueryFilter NEAR and record names")
internal struct QueryFilterNearAndRecordNameTests {
  @Test("near sends NEAR, the location and the distance in meters")
  internal func near() throws {
    let filter = QueryFilter.near(
      "venue",
      Location(latitude: 51.5, longitude: -0.12),
      distance: 25_000
    )
    let components = Components.Schemas.Filter(from: filter)
    #expect(components.comparator == .NEAR)
    #expect(components.fieldName == "venue")
    #expect(components.distance == 25_000)
    guard case .LocationValue(let location) = components.fieldValue?.value else {
      Issue.record("expected a location value")
      return
    }
    #expect(location.latitude == 51.5)
    #expect(location.longitude == -0.12)
  }

  @Test("recordName filters ___recordID with a reference")
  internal func recordName() throws {
    for (filter, comparator) in [
      (
        QueryFilter.recordName(equals: "match-1"),
        Components.Schemas.Filter.comparatorPayload.EQUALS
      ),
      (QueryFilter.recordName(notEquals: "match-1"), .NOT_EQUALS),
    ] {
      let components = Components.Schemas.Filter(from: filter)
      #expect(components.comparator == comparator)
      #expect(components.fieldName == "___recordID")
      guard case .ReferenceValue(let reference) = components.fieldValue?.value else {
        Issue.record("expected a reference value")
        return
      }
      #expect(reference.recordName == "match-1")
    }
  }

  @Test("allowed comparators per field type")
  internal func allowedComparators() {
    #expect(SchemaFieldType(.location).allowedComparators == [.near])
    #expect(SchemaFieldType(.reference).allowedComparators.contains(.equals))
    #expect(!SchemaFieldType(.reference).allowedComparators.contains(.lessThan))
    #expect(SchemaFieldType(.int64).allowedComparators.contains(.greaterThan))
    #expect(SchemaFieldType(.string).allowedComparators.contains(.beginsWith))
    #expect(
      SchemaFieldType(.string, isList: true).allowedComparators
        == [.listContains, .notListContains, .listMemberBeginsWith, .notListMemberBeginsWith]
    )
    #expect(
      SchemaFieldType(.int64, isList: true).allowedComparators
        == [.listContains, .notListContains]
    )
    #expect(SchemaFieldType(.string, isEncrypted: true).allowedComparators.isEmpty)
    #expect(SchemaFieldType(.bytes).allowedComparators.isEmpty)
  }

  @Test("range comparators need a SORTABLE index")
  internal func sortableRange() {
    let range = FilterComparator.allCases.filter(\.requiresSortableIndex)
    #expect(range == [.lessThan, .lessThanOrEquals, .greaterThan, .greaterThanOrEquals])
    #expect(FilterComparator.near.rawValue == "NEAR")
    #expect(FilterComparator.containsAnyTokens.requiresSearchableIndex)
  }
}

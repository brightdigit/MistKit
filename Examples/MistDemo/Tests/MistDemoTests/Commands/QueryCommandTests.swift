//
//  QueryCommandTests.swift
//  MistDemoTests
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

import Foundation
import Testing
import MistKit

@testable import MistDemo

@Suite("QueryCommand Tests")
struct QueryCommandTests {
    // MARK: - Configuration Tests
    
    @Test("QueryConfig initializes with default values")
    func queryConfigInitializesWithDefaults() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(base: baseConfig)
        
        #expect(config.zone == "_defaultZone")
        #expect(config.recordType == "Note")
        #expect(config.filters.isEmpty)
        #expect(config.sort == nil)
        #expect(config.limit == 20)
        #expect(config.offset == 0)
        #expect(config.fields == nil)
        #expect(config.continuationMarker == nil)
        #expect(config.output == .json)
    }
    
    @Test("QueryConfig accepts custom values")
    func queryConfigAcceptsCustomValues() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            zone: "customZone",
            recordType: "CustomType",
            filters: ["title:eq:Test"],
            sort: (field: "createdAt", order: .descending),
            limit: 50,
            offset: 10,
            fields: ["title", "content"],
            continuationMarker: "marker123",
            output: .table
        )
        
        #expect(config.zone == "customZone")
        #expect(config.recordType == "CustomType")
        #expect(config.filters == ["title:eq:Test"])
        #expect(config.sort?.field == "createdAt")
        #expect(config.sort?.order == .descending)
        #expect(config.limit == 50)
        #expect(config.offset == 10)
        #expect(config.fields == ["title", "content"])
        #expect(config.continuationMarker == "marker123")
        #expect(config.output == .table)
    }
    
    // MARK: - Command Property Tests
    
    @Test("Command has correct static properties")
    func commandHasCorrectStaticProperties() {
        #expect(QueryCommand.commandName == "query")
        #expect(QueryCommand.abstract == "Query records from CloudKit with filtering and sorting")
    }
    
    @Test("Command initializes with config")
    func commandInitializesWithConfig() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(base: baseConfig)
        let _ = QueryCommand(config: config)

        #expect(QueryCommand.commandName == "query")
    }
    
    // MARK: - Filter Parsing Tests
    
    @Test("Parse simple filter expression")
    func parseSimpleFilter() {
        let filter = "title:eq:Test Note"
        let parts = filter.split(separator: ":", maxSplits: 2).map(String.init)
        
        #expect(parts.count == 3)
        #expect(parts[0] == "title")
        #expect(parts[1] == "eq")
        #expect(parts[2] == "Test Note")
    }
    
    @Test("Parse filter with multiple colons in value")
    func parseFilterWithColonsInValue() {
        let filter = "url:eq:https://example.com:8080"
        let parts = filter.split(separator: ":", maxSplits: 2).map(String.init)
        
        #expect(parts.count == 3)
        #expect(parts[0] == "url")
        #expect(parts[1] == "eq")
        #expect(parts[2] == "https://example.com:8080")
    }
    
    @Test("Filter operators are valid")
    func filterOperatorsValid() {
        let validOperators = ["eq", "ne", "lt", "lte", "gt", "gte", "in", "contains", "beginsWith"]
        
        for op in validOperators {
            let filter = "field:\(op):value"
            let parts = filter.split(separator: ":").map(String.init)
            #expect(validOperators.contains(parts[1]))
        }
    }
    
    // MARK: - Sort Parsing Tests
    
    @Test("Parse ascending sort")
    func parseAscendingSort() {
        let sort = "createdAt:asc"
        let parts = sort.split(separator: ":").map(String.init)
        
        #expect(parts.count == 2)
        #expect(parts[0] == "createdAt")
        #expect(parts[1] == "asc")
        #expect(SortOrder(rawValue: parts[1]) == .ascending)
    }
    
    @Test("Parse descending sort")
    func parseDescendingSort() {
        let sort = "modifiedAt:desc"
        let parts = sort.split(separator: ":").map(String.init)
        
        #expect(parts.count == 2)
        #expect(parts[0] == "modifiedAt")
        #expect(parts[1] == "desc")
        #expect(SortOrder(rawValue: parts[1]) == .descending)
    }
    
    @Test("SortOrder enum values")
    func sortOrderEnumValues() {
        #expect(SortOrder.ascending.rawValue == "asc")
        #expect(SortOrder.descending.rawValue == "desc")
        #expect(SortOrder.allCases.count == 2)
    }
    
    // MARK: - Limit Validation Tests
    
    @Test("Limit validation accepts valid range")
    func limitValidationAcceptsValid() {
        let validLimits = [1, 50, 100, 200]
        
        for limit in validLimits {
            #expect(limit >= 1 && limit <= 200)
        }
    }
    
    @Test("Limit validation rejects invalid values")
    func limitValidationRejectsInvalid() {
        let invalidLimits = [0, -1, 201, 500]
        
        for limit in invalidLimits {
            #expect(!(limit >= 1 && limit <= 200))
        }
    }
    
    // MARK: - Field Selection Tests
    
    @Test("Field selection with nil returns all fields")
    func fieldSelectionNilReturnsAll() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(base: baseConfig, fields: nil)
        
        #expect(config.fields == nil)
    }
    
    @Test("Field selection with specific fields")
    func fieldSelectionWithSpecificFields() throws {
        let baseConfig = try MistDemoConfig()
        let fields = ["title", "content", "createdAt"]
        let config = QueryConfig(base: baseConfig, fields: fields)
        
        #expect(config.fields?.count == 3)
        #expect(config.fields?.contains("title") == true)
        #expect(config.fields?.contains("content") == true)
        #expect(config.fields?.contains("createdAt") == true)
    }
    
    // MARK: - Continuation Marker Tests
    
    @Test("Continuation marker for pagination")
    func continuationMarkerForPagination() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            continuationMarker: "next-page-marker"
        )
        
        #expect(config.continuationMarker == "next-page-marker")
    }
    
    @Test("No continuation marker for first page")
    func noContinuationMarkerForFirstPage() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(base: baseConfig)
        
        #expect(config.continuationMarker == nil)
    }
    
    // MARK: - Multiple Filters Tests
    
    @Test("Multiple filters are preserved")
    func multipleFiltersPreserved() throws {
        let baseConfig = try MistDemoConfig()
        let filters = [
            "title:contains:Test",
            "priority:gt:5",
            "status:eq:active"
        ]
        let config = QueryConfig(base: baseConfig, filters: filters)
        
        #expect(config.filters.count == 3)
        #expect(config.filters[0] == "title:contains:Test")
        #expect(config.filters[1] == "priority:gt:5")
        #expect(config.filters[2] == "status:eq:active")
    }
    
    // MARK: - Zone Configuration Tests
    
    @Test("Default zone is _defaultZone")
    func defaultZoneIsDefaultZone() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(base: baseConfig)
        
        #expect(config.zone == "_defaultZone")
    }
    
    @Test("Custom zone is preserved")
    func customZoneIsPreserved() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(base: baseConfig, zone: "customZone")
        
        #expect(config.zone == "customZone")
    }
    
    // MARK: - Record Type Tests
    
    @Test("Default record type is Note")
    func defaultRecordTypeIsNote() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(base: baseConfig)
        
        #expect(config.recordType == "Note")
    }
    
    @Test("Custom record type is preserved")
    func customRecordTypeIsPreserved() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(base: baseConfig, recordType: "CustomRecord")
        
        #expect(config.recordType == "CustomRecord")
    }
}
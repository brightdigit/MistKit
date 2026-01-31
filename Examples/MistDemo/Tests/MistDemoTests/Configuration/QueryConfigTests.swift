//
//  QueryConfigTests.swift
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

@Suite("QueryConfig Tests")
struct QueryConfigTests {
    // MARK: - Basic Initialization Tests

    @Test("QueryConfig initializes with default values")
    func initializeWithDefaults() throws {
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

    @Test("QueryConfig initializes with custom zone")
    func initializeWithCustomZone() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            zone: "customZone"
        )

        #expect(config.zone == "customZone")
        #expect(config.recordType == "Note")
    }

    @Test("QueryConfig initializes with custom record type")
    func initializeWithCustomRecordType() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            recordType: "Article"
        )

        #expect(config.zone == "_defaultZone")
        #expect(config.recordType == "Article")
    }

    // MARK: - Filter Tests

    @Test("QueryConfig initializes with empty filters")
    func initializeWithEmptyFilters() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            filters: []
        )

        #expect(config.filters.isEmpty)
    }

    @Test("QueryConfig initializes with single filter")
    func initializeWithSingleFilter() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            filters: ["status=active"]
        )

        #expect(config.filters.count == 1)
        #expect(config.filters[0] == "status=active")
    }

    @Test("QueryConfig initializes with multiple filters")
    func initializeWithMultipleFilters() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            filters: ["status=active", "priority>5", "category=urgent"]
        )

        #expect(config.filters.count == 3)
        #expect(config.filters[0] == "status=active")
        #expect(config.filters[1] == "priority>5")
        #expect(config.filters[2] == "category=urgent")
    }

    // MARK: - Sort Option Tests

    @Test("QueryConfig initializes with nil sort")
    func initializeWithNilSort() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            sort: nil
        )

        #expect(config.sort == nil)
    }

    @Test("QueryConfig initializes with ascending sort")
    func initializeWithAscendingSort() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            sort: (field: "createdAt", order: .ascending)
        )

        #expect(config.sort?.field == "createdAt")
        #expect(config.sort?.order == .ascending)
    }

    @Test("QueryConfig initializes with descending sort")
    func initializeWithDescendingSort() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            sort: (field: "updatedAt", order: .descending)
        )

        #expect(config.sort?.field == "updatedAt")
        #expect(config.sort?.order == .descending)
    }

    @Test("QueryConfig handles sort on different field names")
    func handleSortOnDifferentFields() throws {
        let baseConfig = try MistDemoConfig()

        let config1 = QueryConfig(base: baseConfig, sort: (field: "title", order: .ascending))
        #expect(config1.sort?.field == "title")

        let config2 = QueryConfig(base: baseConfig, sort: (field: "priority", order: .descending))
        #expect(config2.sort?.field == "priority")

        let config3 = QueryConfig(base: baseConfig, sort: (field: "status_code", order: .ascending))
        #expect(config3.sort?.field == "status_code")
    }

    // MARK: - Limit Tests

    @Test("QueryConfig initializes with default limit")
    func initializeWithDefaultLimit() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(base: baseConfig)

        #expect(config.limit == 20)
    }

    @Test("QueryConfig initializes with custom limit")
    func initializeWithCustomLimit() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            limit: 50
        )

        #expect(config.limit == 50)
    }

    @Test("QueryConfig handles minimum limit")
    func handleMinimumLimit() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            limit: 1
        )

        #expect(config.limit == 1)
    }

    @Test("QueryConfig handles maximum limit")
    func handleMaximumLimit() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            limit: 200
        )

        #expect(config.limit == 200)
    }

    // MARK: - Offset Tests

    @Test("QueryConfig initializes with default offset")
    func initializeWithDefaultOffset() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(base: baseConfig)

        #expect(config.offset == 0)
    }

    @Test("QueryConfig initializes with custom offset")
    func initializeWithCustomOffset() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            offset: 10
        )

        #expect(config.offset == 10)
    }

    @Test("QueryConfig handles large offset")
    func handleLargeOffset() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            offset: 1000
        )

        #expect(config.offset == 1000)
    }

    // MARK: - Fields Filter Tests

    @Test("QueryConfig initializes with nil fields")
    func initializeWithNilFields() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            fields: nil
        )

        #expect(config.fields == nil)
    }

    @Test("QueryConfig initializes with empty fields array")
    func initializeWithEmptyFieldsArray() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            fields: []
        )

        #expect(config.fields != nil)
        #expect(config.fields?.isEmpty == true)
    }

    @Test("QueryConfig initializes with single field")
    func initializeWithSingleField() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            fields: ["title"]
        )

        #expect(config.fields?.count == 1)
        #expect(config.fields?[0] == "title")
    }

    @Test("QueryConfig initializes with multiple fields")
    func initializeWithMultipleFields() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            fields: ["title", "content", "createdAt", "status"]
        )

        #expect(config.fields?.count == 4)
        #expect(config.fields?[0] == "title")
        #expect(config.fields?[3] == "status")
    }

    // MARK: - Continuation Marker Tests

    @Test("QueryConfig initializes with nil continuation marker")
    func initializeWithNilContinuationMarker() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            continuationMarker: nil
        )

        #expect(config.continuationMarker == nil)
    }

    @Test("QueryConfig initializes with continuation marker")
    func initializeWithContinuationMarker() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            continuationMarker: "marker-abc123"
        )

        #expect(config.continuationMarker == "marker-abc123")
    }

    // MARK: - Output Format Tests

    @Test("QueryConfig initializes with JSON output format")
    func initializeWithJSONOutput() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            output: .json
        )

        #expect(config.output == .json)
    }

    @Test("QueryConfig initializes with CSV output format")
    func initializeWithCSVOutput() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            output: .csv
        )

        #expect(config.output == .csv)
    }

    @Test("QueryConfig initializes with table output format")
    func initializeWithTableOutput() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            output: .table
        )

        #expect(config.output == .table)
    }

    @Test("QueryConfig initializes with YAML output format")
    func initializeWithYAMLOutput() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            output: .yaml
        )

        #expect(config.output == .yaml)
    }

    // MARK: - Complex Initialization Tests

    @Test("QueryConfig initializes with all custom values")
    func initializeWithAllCustomValues() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            zone: "customZone",
            recordType: "Article",
            filters: ["status=published", "category=tech"],
            sort: (field: "publishedAt", order: .descending),
            limit: 50,
            offset: 20,
            fields: ["title", "content", "author"],
            continuationMarker: "marker-xyz789",
            output: .yaml
        )

        #expect(config.zone == "customZone")
        #expect(config.recordType == "Article")
        #expect(config.filters.count == 2)
        #expect(config.sort?.field == "publishedAt")
        #expect(config.sort?.order == .descending)
        #expect(config.limit == 50)
        #expect(config.offset == 20)
        #expect(config.fields?.count == 3)
        #expect(config.continuationMarker == "marker-xyz789")
        #expect(config.output == .yaml)
    }

    @Test("QueryConfig handles pagination scenario")
    func handlePaginationScenario() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            limit: 10,
            offset: 30,
            continuationMarker: "page-4"
        )

        #expect(config.limit == 10)
        #expect(config.offset == 30)
        #expect(config.continuationMarker == "page-4")
    }

    // MARK: - Edge Cases

    @Test("QueryConfig handles special characters in filters")
    func handleSpecialCharactersInFilters() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            filters: ["name='O'Brien'", "email~='@example.com'"]
        )

        #expect(config.filters.count == 2)
        #expect(config.filters[0] == "name='O'Brien'")
    }

    @Test("QueryConfig handles zero limit")
    func handleZeroLimit() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            limit: 0
        )

        #expect(config.limit == 0)
    }

    @Test("QueryConfig handles fields with special characters")
    func handleFieldsWithSpecialCharacters() throws {
        let baseConfig = try MistDemoConfig()
        let config = QueryConfig(
            base: baseConfig,
            fields: ["field_name", "field-with-dash", "field.with.dot"]
        )

        #expect(config.fields?.count == 3)
        #expect(config.fields?[0] == "field_name")
        #expect(config.fields?[1] == "field-with-dash")
        #expect(config.fields?[2] == "field.with.dot")
    }
}

//
//  QueryCommandTests+ParseFilter.swift
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

internal import Foundation
internal import MistKit
internal import Testing

@testable import MistDemoKit

extension QueryCommandTests {
  @Suite("parseFilter / inferFieldValue / shouldIncludeField")
  internal struct ParseFilter {
    // MARK: - inferFieldValue

    @Test("inferFieldValue parses integer literals as .int64")
    internal func inferInt() {
      #expect(QueryCommand.inferFieldValue("42") == .int64(42))
      #expect(QueryCommand.inferFieldValue("0") == .int64(0))
      #expect(QueryCommand.inferFieldValue("-7") == .int64(-7))
    }

    @Test("inferFieldValue parses non-integer numeric literals as .double")
    internal func inferDouble() {
      #expect(QueryCommand.inferFieldValue("3.14") == .double(3.14))
      #expect(QueryCommand.inferFieldValue("-2.5") == .double(-2.5))
    }

    @Test("inferFieldValue treats unparseable input as .string")
    internal func inferString() {
      #expect(QueryCommand.inferFieldValue("hello") == .string("hello"))
      #expect(QueryCommand.inferFieldValue("12abc") == .string("12abc"))
      #expect(QueryCommand.inferFieldValue("") == .string(""))
    }

    // MARK: - shouldIncludeField

    @Test("shouldIncludeField returns true when filter is nil or empty")
    internal func includeAllByDefault() {
      #expect(QueryCommand.shouldIncludeField("title", fields: nil) == true)
      #expect(QueryCommand.shouldIncludeField("title", fields: []) == true)
    }

    @Test("shouldIncludeField matches case-insensitively")
    internal func caseInsensitiveMatch() {
      #expect(QueryCommand.shouldIncludeField("Title", fields: ["title"]) == true)
      #expect(QueryCommand.shouldIncludeField("title", fields: ["TITLE"]) == true)
      #expect(QueryCommand.shouldIncludeField("Body", fields: ["title", "body"]) == true)
    }

    @Test("shouldIncludeField excludes fields not in filter")
    internal func excludesNonMatches() {
      #expect(QueryCommand.shouldIncludeField("priority", fields: ["title"]) == false)
      #expect(QueryCommand.shouldIncludeField("body", fields: ["title", "priority"]) == false)
    }

    // MARK: - parseFilter — happy paths

    @Test(
      "parseFilter accepts comparison operators",
      arguments: [
        "title:eq:hello",
        "title:equals:hello",
        "title:==:hello",
        "title:=:hello",
        "priority:ne:1",
        "priority:not_equals:1",
        "priority:!=:1",
        "score:gt:10",
        "score:>:10",
        "score:gte:10",
        "score:>=:10",
        "score:lt:10",
        "score:<:10",
        "score:lte:10",
        "score:<=:10",
      ]
    )
    internal func parsesComparisonOperators(filterString: String) throws {
      _ = try QueryCommand.parseFilter(filterString)
    }

    @Test(
      "parseFilter accepts string and list operators",
      arguments: [
        "title:contains:hello world",
        "title:like:hello world",
        "title:begins_with:hello",
        "title:starts_with:hello",
        "priority:in:1,2,3",
        "priority:not_in:1,2,3",
      ]
    )
    internal func parsesSpecialOperators(filterString: String) throws {
      _ = try QueryCommand.parseFilter(filterString)
    }

    @Test("parseFilter accepts operator names in any case")
    internal func operatorCaseInsensitive() throws {
      _ = try QueryCommand.parseFilter("title:EQ:hello")
      _ = try QueryCommand.parseFilter("title:Equals:hello")
      _ = try QueryCommand.parseFilter("title:BEGINS_WITH:hello")
    }

    @Test("parseFilter preserves colons in value (maxSplits=2)")
    internal func valueWithColons() throws {
      _ = try QueryCommand.parseFilter("url:eq:https://example.com:8080/path")
    }

    // MARK: - parseFilter — error paths

    @Test("parseFilter throws invalidFilter when fewer than three components")
    internal func tooFewComponentsThrows() {
      #expect(throws: QueryError.self) {
        _ = try QueryCommand.parseFilter("title:eq")
      }
      #expect(throws: QueryError.self) {
        _ = try QueryCommand.parseFilter("nothing")
      }
    }

    @Test("parseFilter throws emptyFieldName when the field segment is blank")
    internal func emptyFieldThrows() {
      #expect(throws: QueryError.self) {
        _ = try QueryCommand.parseFilter(":eq:value")
      }
      #expect(throws: QueryError.self) {
        _ = try QueryCommand.parseFilter("   :eq:value")
      }
    }

    @Test("parseFilter throws unsupportedOperator for an unknown operator")
    internal func unsupportedOperatorThrows() {
      #expect(throws: QueryError.self) {
        _ = try QueryCommand.parseFilter("title:fuzzy_match:hello")
      }
    }

    // MARK: - buildComparisonFilter

    @Test("buildComparisonFilter returns nil for non-comparison operators")
    internal func buildComparisonFilterReturnsNilForSpecial() {
      let result = QueryCommand.buildComparisonFilter(
        field: "title",
        operatorString: "contains",
        value: "hello"
      )
      #expect(result == nil)
    }

    @Test(
      "buildComparisonFilter returns a filter for each comparison alias",
      arguments: ["eq", "ne", "gt", "gte", "lt", "lte"]
    )
    internal func buildComparisonFilterReturnsNonNil(alias: String) {
      let result = QueryCommand.buildComparisonFilter(
        field: "score",
        operatorString: alias,
        value: "10"
      )
      #expect(result != nil)
    }
  }
}

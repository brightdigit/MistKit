//
//  JSONFormatterTests.swift
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

@testable import MistDemo

@Suite("JSONFormatter Tests")
struct JSONFormatterTests {
  // MARK: - Test Data

  struct TestUser: Codable {
    let name: String
    let age: Int
    let email: String
  }

  struct TestRecord: Codable {
    let recordName: String
    let recordType: String
    let fields: [String: String]
  }

  // MARK: - Basic Formatting Tests

  @Test("Format simple object without pretty printing")
  func formatSimpleObject() throws {
    let user = TestUser(name: "Alice", age: 30, email: "alice@example.com")
    let formatter = JSONFormatter(pretty: false)

    let output = try formatter.format(user)

    #expect(output.contains("\"name\""))
    #expect(output.contains("\"Alice\""))
    #expect(output.contains("\"age\""))
    #expect(output.contains("30"))
    #expect(output.contains("\"email\""))
    #expect(output.contains("alice@example.com"))
  }

  @Test("Format simple object with pretty printing")
  func formatSimpleObjectPretty() throws {
    let user = TestUser(name: "Bob", age: 25, email: "bob@example.com")
    let formatter = JSONFormatter(pretty: true)

    let output = try formatter.format(user)

    // Pretty printed should have newlines and indentation
    #expect(output.contains("\n"))
    #expect(output.contains("  "))
    #expect(output.contains("\"name\" : \"Bob\""))
    #expect(output.contains("\"age\" : 25"))
  }

  @Test("Format array of objects")
  func formatArrayOfObjects() throws {
    let users = [
      TestUser(name: "Charlie", age: 35, email: "charlie@example.com"),
      TestUser(name: "Diana", age: 28, email: "diana@example.com")
    ]
    let formatter = JSONFormatter(pretty: true)

    let output = try formatter.format(users)

    #expect(output.contains("Charlie"))
    #expect(output.contains("Diana"))
    #expect(output.contains("["))
    #expect(output.contains("]"))
  }

  // MARK: - Edge Cases

  @Test("Format empty array")
  func formatEmptyArray() throws {
    let emptyArray: [TestUser] = []
    let formatter = JSONFormatter(pretty: false)

    let output = try formatter.format(emptyArray)

    #expect(output == "[]")
  }

  @Test("Format object with special characters")
  func formatObjectWithSpecialCharacters() throws {
    let user = TestUser(
      name: "Test \"User\"",
      age: 42,
      email: "test@example.com"
    )
    let formatter = JSONFormatter(pretty: false)

    let output = try formatter.format(user)

    // JSON should escape quotes
    #expect(output.contains("\\\""))
  }

  @Test("Format object with nested structure")
  func formatNestedObject() throws {
    let record = TestRecord(
      recordName: "todo-123",
      recordType: "TodoItem",
      fields: [
        "title": "Buy groceries",
        "status": "pending"
      ]
    )
    let formatter = JSONFormatter(pretty: true)

    let output = try formatter.format(record)

    #expect(output.contains("todo-123"))
    #expect(output.contains("TodoItem"))
    #expect(output.contains("Buy groceries"))
    #expect(output.contains("pending"))
  }

  // MARK: - Pretty Printing Tests

  @Test("Pretty printing produces sorted keys")
  func prettyPrintingSortsKeys() throws {
    let user = TestUser(name: "Zoe", age: 40, email: "zoe@example.com")
    let formatter = JSONFormatter(pretty: true)

    let output = try formatter.format(user)

    // Keys should be sorted: age, email, name
    let ageIndex = output.range(of: "\"age\"")?.lowerBound
    let emailIndex = output.range(of: "\"email\"")?.lowerBound
    let nameIndex = output.range(of: "\"name\"")?.lowerBound

    #expect(ageIndex != nil)
    #expect(emailIndex != nil)
    #expect(nameIndex != nil)

    if let age = ageIndex, let email = emailIndex, let name = nameIndex {
      #expect(age < email)
      #expect(email < name)
    }
  }

  @Test("Non-pretty printing is compact")
  func nonPrettyPrintingIsCompact() throws {
    let user = TestUser(name: "Frank", age: 50, email: "frank@example.com")
    let formatter = JSONFormatter(pretty: false)

    let output = try formatter.format(user)

    // Should not have unnecessary whitespace
    let lines = output.components(separatedBy: "\n")
    #expect(lines.count == 1)
  }
}

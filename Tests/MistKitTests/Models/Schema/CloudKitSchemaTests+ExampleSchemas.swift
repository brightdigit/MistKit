//
//  CloudKitSchemaTests+ExampleSchemas.swift
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
internal import Testing

@testable import MistKit

extension CloudKitSchemaTests {
  @Suite("Example schemas")
  internal struct ExampleSchemas {
    private static let packageRoot = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()  // Schema
      .deletingLastPathComponent()  // Models
      .deletingLastPathComponent()  // MistKitTests
      .deletingLastPathComponent()  // Tests
      .deletingLastPathComponent()

    @Test(
      "Every committed example .ckdb parses",
      arguments: [
        "Examples/MistDemo/schema.ckdb",
        "Examples/BushelCloud/schema.ckdb",
        "Examples/CelestraCloud/schema.ckdb",
      ]
    )
    internal func parses(relativePath: String) throws {
      let url = Self.packageRoot.appendingPathComponent(relativePath)
      try #require(FileManager.default.fileExists(atPath: url.path))
      let text = try String(contentsOf: url, encoding: .utf8)
      let schema = try CloudKitSchema(parsing: text)
      #expect(!schema.recordTypes.isEmpty)
    }

    @Test("MistDemo's Note keeps its index flags and encrypted field")
    internal func mistDemoNote() throws {
      let url = Self.packageRoot.appendingPathComponent("Examples/MistDemo/schema.ckdb")
      let schema = try CloudKitSchema(parsing: try String(contentsOf: url, encoding: .utf8))
      let note = try #require(schema.recordType(named: "Note"))
      let title = try #require(note.field(named: "title"))
      #expect(title.isQueryable && title.isSortable && title.isSearchable)
      #expect(note.field(named: "secret")?.type == SchemaFieldType(.string, isEncrypted: true))
      #expect(note.field(named: "tags")?.type == SchemaFieldType(.string, isList: true))
      #expect(
        note.grants.first == SchemaGrant(permissions: [.read, .create, .write], role: "_creator")
      )
    }
  }
}

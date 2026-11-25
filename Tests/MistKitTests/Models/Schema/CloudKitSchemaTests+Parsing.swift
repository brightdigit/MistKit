//
//  CloudKitSchemaTests+Parsing.swift
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
  @Suite("Parsing")
  internal struct Parsing {
    /// Apple's sample schema from "Integrating a Text-Based Schema into Your
    /// Workflow" (developer.apple.com/documentation/cloudkit), reindented.
    private static let appleSample = """
      DEFINE SCHEMA
        CREATE ROLE DeptManager;

        RECORD TYPE Department (
          "___createTime" TIMESTAMP QUERYABLE SORTABLE,
          "___recordID" REFERENCE QUERYABLE,
          name STRING,
          address STRING,
          phone LIST<STRING>,
          employees LIST<REFERENCE>,
          GRANT WRITE TO "_creator",
          GRANT CREATE TO "_icloud",
          GRANT READ TO "_world",
          GRANT WRITE, CREATE, READ TO DeptManager
        );

        RECORD TYPE Employee (
          "___createTime" TIMESTAMP QUERYABLE SORTABLE,
          "___recordID" REFERENCE QUERYABLE,
          name STRING,
          address STRING,
          hiredate TIMESTAMP,
          salary INT64,
          GRANT WRITE TO "_creator",
          GRANT CREATE TO "_icloud",
          GRANT READ TO "_world"
        );
      """

    @Test("Apple's sample schema yields its roles and record types in order")
    internal func appleSampleStructure() throws {
      let schema = try CloudKitSchema(parsing: Self.appleSample)
      #expect(schema.roles == ["DeptManager"])
      #expect(schema.recordTypes.map(\.name) == ["Department", "Employee"])
      let department = try #require(schema.recordType(named: "Department"))
      #expect(
        department.fields.map(\.name) == [
          "___createTime", "___recordID", "name", "address", "phone", "employees",
        ]
      )
    }

    @Test("Index options map to per-field QUERYABLE / SORTABLE / SEARCHABLE flags")
    internal func indexFlags() throws {
      let schema = try CloudKitSchema(
        parsing: """
          DEFINE SCHEMA
          RECORD TYPE Note (
            "title" STRING QUERYABLE SORTABLE SEARCHABLE,
            "index" INT64 SORTABLE,
            body STRING
          );
          """
      )
      let note = try #require(schema.recordType(named: "Note"))
      let title = try #require(note.field(named: "title"))
      #expect(title.isQueryable && title.isSortable && title.isSearchable)
      let index = try #require(note.field(named: "index"))
      #expect(!index.isQueryable && index.isSortable && !index.isSearchable)
      let body = try #require(note.field(named: "body"))
      #expect(!body.isQueryable && !body.isSortable && !body.isSearchable)
    }

    @Test("Quoted identifiers keep reserved words and leading underscores")
    internal func quotedIdentifiers() throws {
      let schema = try CloudKitSchema(
        parsing: """
          DEFINE SCHEMA
          RECORD TYPE "grant" (
            "queryable" STRING,
            "___recordID" REFERENCE QUERYABLE
          );
          """
      )
      let type = try #require(schema.recordType(named: "grant"))
      #expect(type.fields.map(\.name) == ["queryable", "___recordID"])
      #expect(type.field(named: "___recordID")?.isSystemField == true)
      #expect(type.field(named: "queryable")?.isSystemField == false)
    }

    @Test(
      "Data types parse into primitive, list and encrypted forms",
      arguments: [
        ("ASSET", SchemaFieldType(.asset)),
        ("BYTES", SchemaFieldType(.bytes)),
        ("DOUBLE", SchemaFieldType(.double)),
        ("INT64", SchemaFieldType(.int64)),
        ("LOCATION", SchemaFieldType(.location)),
        ("REFERENCE", SchemaFieldType(.reference)),
        ("STRING", SchemaFieldType(.string)),
        ("TIMESTAMP", SchemaFieldType(.timestamp)),
        ("NUMBER", SchemaFieldType(.number(preferredAs: nil))),
        ("NUMBER PREFERRED AS INT64", SchemaFieldType(.number(preferredAs: .int64))),
        ("NUMBER PREFERRED AS DOUBLE", SchemaFieldType(.number(preferredAs: .double))),
        ("ENCRYPTED STRING", SchemaFieldType(.string, isEncrypted: true)),
        ("LIST<STRING>", SchemaFieldType(.string, isList: true)),
        ("LIST<REFERENCE>", SchemaFieldType(.reference, isList: true)),
        (
          "LIST< ENCRYPTED TIMESTAMP >",
          SchemaFieldType(.timestamp, isEncrypted: true, isList: true)
        ),
      ]
    )
    internal func dataTypes(source: String, expected: SchemaFieldType) throws {
      let schema = try CloudKitSchema(
        parsing: "DEFINE SCHEMA RECORD TYPE T ( f \(source) QUERYABLE );"
      )
      let field = try #require(schema.recordType(named: "T")?.field(named: "f"))
      #expect(field.type == expected)
      #expect(field.isQueryable)
    }

    @Test("Grants keep every permission and the role they go to")
    internal func grants() throws {
      let schema = try CloudKitSchema(parsing: Self.appleSample)
      let department = try #require(schema.recordType(named: "Department"))
      #expect(
        department.grants == [
          SchemaGrant(permissions: [.write], role: "_creator"),
          SchemaGrant(permissions: [.create], role: "_icloud"),
          SchemaGrant(permissions: [.read], role: "_world"),
          SchemaGrant(permissions: [.write, .create, .read], role: "DeptManager"),
        ]
      )
    }

    @Test("A schema with no record types parses as empty")
    internal func emptySchema() throws {
      let schema = try CloudKitSchema(parsing: "DEFINE SCHEMA\n")
      #expect(schema.recordTypes.isEmpty)
      #expect(schema.roles.isEmpty)
    }

    @Test("A record type with only grants and a trailing comma parses")
    internal func trailingCommaAndGrantOnly() throws {
      let schema = try CloudKitSchema(
        parsing: """
          DEFINE SCHEMA
          RECORD TYPE Users (
            roles LIST<INT64>,
            GRANT WRITE TO "_creator",
          );
          """
      )
      let users = try #require(schema.recordType(named: "Users"))
      #expect(users.fields.map(\.name) == ["roles"])
      #expect(users.grants.count == 1)
    }
  }
}

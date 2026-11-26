//
//  CloudKitSchemaTests+Grants.swift
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
  @Suite("Merged grants and implicit fields")
  internal struct Grants {
    private static let vault = """
      DEFINE SCHEMA RECORD TYPE Vault (
        body STRING,
        GRANT WRITE TO "_creator", GRANT READ TO "_world", GRANT READ TO "_creator",
        GRANT CREATE, WRITE TO Moderator, GRANT CREATE TO "_creator"
      );
      """

    @Test("grants merge per role, in first-seen role order and READ, CREATE, WRITE order")
    internal func merged() throws {
      let vault = try #require(
        try CloudKitSchema(parsing: Self.vault).recordType(named: "Vault")
      )
      #expect(
        vault.mergedGrants == [
          SchemaGrant(permissions: [.read, .create, .write], role: "_creator"),
          SchemaGrant(permissions: [.read], role: "_world"),
          SchemaGrant(permissions: [.create, .write], role: "Moderator"),
        ]
      )
      #expect(vault.permissions(for: "_creator") == [.read, .create, .write])
      #expect(vault.permissions(for: "_icloud").isEmpty)
    }

    @Test("a record type with no grants has no merged grants")
    internal func noGrants() {
      #expect(SchemaRecordType(name: "Empty").mergedGrants.isEmpty)
    }

    @Test("unlisted system fields come first, unindexed; listed ones keep their indexes")
    internal func implicitFields() throws {
      let note = try #require(
        try CloudKitSchema(
          parsing: """
            DEFINE SCHEMA RECORD TYPE Note ("___modTime" TIMESTAMP SORTABLE, body STRING);
            """
        )
        .recordType(named: "Note")
      )
      let fields = note.fieldsIncludingImplicit
      #expect(
        fields.map(\.name) == [
          "___createTime", "___createdBy", "___etag", "___modifiedBy", "___recordID",
          "___modTime", "body",
        ]
      )
      #expect(fields.filter(\.isSystemField).count == 6)
      #expect(note.fieldIncludingImplicit(named: "___modTime")?.isSortable == true)
      #expect(note.fieldIncludingImplicit(named: "___recordID")?.isQueryable == false)
      #expect(note.fieldIncludingImplicit(named: "___recordID")?.resolvedType == .reference)
      #expect(note.field(named: "___recordID") == nil)
      #expect(note.fieldIncludingImplicit(named: "missing") == nil)
    }
  }
}

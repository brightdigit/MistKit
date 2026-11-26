//
//  SchemaSourceTests+File.swift
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

extension SchemaSourceTests {
  @Suite("File")
  internal struct File {
    private static let schemaText = """
      DEFINE SCHEMA
        RECORD TYPE Player (displayName STRING QUERYABLE, GRANT READ TO "_world");
      """

    private let url: URL

    internal init() throws {
      let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("FileSchemaSourceTests-\(UUID().uuidString)")
      try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true
      )
      url = directory.appendingPathComponent("schema.ckdb")
      try Data(Self.schemaText.utf8).write(to: url)
    }

    @Test("CloudKitSchema(contentsOf:) reads and parses a file")
    internal func contentsOf() throws {
      let schema = try CloudKitSchema(contentsOf: url)
      #expect(
        schema.recordType(named: "Player")?.field(named: "displayName")?.isQueryable == true
      )
    }

    @Test("loads the file")
    internal func loads() async throws {
      let source = FileSchemaSource(url: url)
      let schema = try await source.loadSchema()
      #expect(source.url == url)
      #expect(schema == (try CloudKitSchema(parsing: Self.schemaText)))
      #expect(
        schema.recordType(named: "Player")?.mergedGrants
          == [SchemaGrant(permissions: [.read], role: "_world")]
      )
    }

    @Test("a malformed file throws SchemaParseError with the line and column")
    internal func malformed() async throws {
      try Data("DEFINE SCHEMA\n  RECORD TYPE Player (name);".utf8).write(to: url)
      await #expect {
        _ = try await FileSchemaSource(url: url).loadSchema()
      } throws: { error in
        guard let error = error as? SchemaParseError else {
          return false
        }
        return error.line == 2 && error.column == 27
          && error.message == "expected a data type, found \")\""
      }
    }

    @Test("a missing file throws unreadableFile naming the file")
    internal func missing() async throws {
      try FileManager.default.removeItem(at: url)
      await #expect {
        _ = try await FileSchemaSource(url: url).loadSchema()
      } throws: { error in
        guard case .unreadableFile(let failedURL, _) = error as? SchemaSourceError else {
          return false
        }
        return failedURL == url
          && (error as? SchemaSourceError)?.errorDescription?.contains("schema.ckdb") == true
      }
      #expect(throws: SchemaSourceError.self) {
        try CloudKitSchema(contentsOf: url)
      }
    }

    @Test("a file that isn't UTF-8 throws notUTF8")
    internal func notUTF8() async throws {
      try Data([0xFF, 0xFE, 0xC3, 0x28]).write(to: url)
      await #expect {
        _ = try await FileSchemaSource(url: url).loadSchema()
      } throws: { error in
        guard case .notUTF8(let failedURL) = error as? SchemaSourceError else {
          return false
        }
        return failedURL == url
      }
    }

    @Test("asks for a reload when the file's bytes change, not on every notification")
    internal func reloadsOnChange() async throws {
      let (notifications, notify) = try SchemaSourceTests.notifications()
      let source = FileSchemaSource(url: url) { notifications }
      _ = try await source.loadSchema()
      var changes = source.schemaChanges().makeAsyncIterator()

      // Two notifications, one edit: exactly one reload, whichever notification
      // the source sees the edit on. The write is atomic: a plain write
      // truncates first, so a notification read mid-write would see a
      // half-written file as a second change. WASI has no temporary files, so
      // no atomic writes.
      notify.yield()
      let edited = Data((Self.schemaText + "\n// edited").utf8)
      #if os(WASI)
        try edited.write(to: url)
      #else
        try edited.write(to: url, options: .atomic)
      #endif
      notify.yield()
      notify.finish()

      #expect(await changes.next() != nil)
      #expect(await changes.next() == nil)
    }

    @Test("doesn't ask for a reload when a save rewrites the same bytes")
    internal func sameBytes() async throws {
      let (notifications, notify) = try SchemaSourceTests.notifications()
      let source = FileSchemaSource(url: url) { notifications }
      _ = try await source.loadSchema()
      var changes = source.schemaChanges().makeAsyncIterator()
      try Data(Self.schemaText.utf8).write(to: url)
      notify.yield()
      notify.finish()
      #expect(await changes.next() == nil)
    }

    @Test("asks for a reload when the file disappears, so the error shows")
    internal func reloadsOnDelete() async throws {
      let (notifications, notify) = try SchemaSourceTests.notifications()
      let source = FileSchemaSource(url: url) { notifications }
      _ = try await source.loadSchema()
      var changes = source.schemaChanges().makeAsyncIterator()
      try FileManager.default.removeItem(at: url)
      notify.yield()
      notify.finish()
      #expect(await changes.next() != nil)
    }

    @Test("with no change notifications, schemaChanges finishes at once")
    internal func noNotifications() async {
      var changes = FileSchemaSource(url: url).schemaChanges().makeAsyncIterator()
      #expect(await changes.next() == nil)
    }
  }
}

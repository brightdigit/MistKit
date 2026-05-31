//
//  CloudKitServiceTests.Rereference+ComposeErrors.swift
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

extension CloudKitServiceTests.Rereference {
  @Suite("Rereference Asset Compose Errors")
  internal struct ComposeErrors {
    private typealias Helper = CloudKitServiceTests.Rereference

    /// Field keys written by the first operation in a `records/modify` body.
    private static func modifyFieldKeys(from body: Data) throws -> Set<String> {
      let json = try JSONSerialization.jsonObject(with: body)
      let object = try #require(json as? [String: Any])
      let operations = try #require(object["operations"] as? [[String: Any]])
      let record = try #require(operations.first?["record"] as? [String: Any])
      let fields = try #require(record["fields"] as? [String: Any])
      return Set(fields.keys)
    }

    @Test("rereferenceAsset throws .incompleteResponse when no source descriptor is returned")
    internal func throwsWhenNoSourceDescriptor() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      // The overload supplies recordType/changeTag, so the only round trip is
      // assets/rereference — here it returns an empty descriptor list.
      let service = try Helper.makeService(responsesByOperation: [
        "rereferenceAssets": try Helper.rereferenceResponse(assets: [])
      ])

      let error = await #expect(throws: CloudKitError.self) {
        _ = try await service.rereferenceAsset(
          fromRecord: "note-a",
          field: "image",
          toRecord: "note-b",
          recordType: "Note",
          recordChangeTag: "tag-b",
          database: Helper.publicDatabase
        )
      }
      guard case .incompleteResponse(let reason) = error else {
        Issue.record("Expected .incompleteResponse, got \(String(describing: error))")
        return
      }
      #expect(reason.contains("note-a"))
      #expect(reason.contains("image"))
    }

    @Test("rereferenceAsset throws .incompleteResponse when the target record is not found")
    internal func throwsWhenTargetNotFound() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Helper.makeService(responsesByOperation: [
        "rereferenceAssets": try Helper.rereferenceResponse(assets: [
          Helper.assetDictionary(fileChecksum: "shared-chk")
        ]),
        "lookupRecords": try Helper.recordsResponse([]),
      ])

      let error = await #expect(throws: CloudKitError.self) {
        _ = try await service.rereferenceAsset(
          fromRecord: "note-a",
          field: "image",
          toRecord: "missing-target",
          database: Helper.publicDatabase
        )
      }
      guard case .incompleteResponse(let reason) = error else {
        Issue.record("Expected .incompleteResponse, got \(String(describing: error))")
        return
      }
      #expect(reason.contains("missing-target"))
      #expect(reason.contains("not found"))
    }

    @Test("rereferenceAsset throws .incompleteResponse when the target has no recordType")
    internal func throwsWhenTargetHasNoRecordType() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Helper.makeService(responsesByOperation: [
        "rereferenceAssets": try Helper.rereferenceResponse(assets: [
          Helper.assetDictionary(fileChecksum: "shared-chk")
        ]),
        "lookupRecords": try Helper.recordsResponse([
          Helper.recordWithoutType(recordName: "note-b")
        ]),
      ])

      let error = await #expect(throws: CloudKitError.self) {
        _ = try await service.rereferenceAsset(
          fromRecord: "note-a",
          field: "image",
          toRecord: "note-b",
          database: Helper.publicDatabase
        )
      }
      guard case .incompleteResponse(let reason) = error else {
        Issue.record("Expected .incompleteResponse, got \(String(describing: error))")
        return
      }
      #expect(reason.contains("recordType"))
    }

    @Test("rereferenceAsset writes onto assetField when targetField is omitted")
    internal func defaultsTargetFieldToAssetField() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let (service, provider) = try Helper.makeServiceWithProvider(responsesByOperation: [
        "rereferenceAssets": try Helper.rereferenceResponse(assets: [
          Helper.assetDictionary(fileChecksum: "shared-chk")
        ]),
        "lookupRecords": try Helper.recordsResponse([
          Helper.noteRecord(recordName: "note-b", changeTag: "tag-b")
        ]),
        "modifyRecords": try Helper.recordsResponse([
          Helper.noteRecord(recordName: "note-b", changeTag: "tag-b2", imageChecksum: "shared-chk")
        ]),
      ])

      // No `field:` argument — the target field must default to the source field.
      _ = try await service.rereferenceAsset(
        fromRecord: "note-a",
        field: "photo",
        toRecord: "note-b",
        database: Helper.publicDatabase
      )

      let modifyBodies = await provider.bodies(for: "modifyRecords")
      let body = try #require(modifyBodies.first.flatMap { $0 })
      let fieldKeys = try Self.modifyFieldKeys(from: body)
      #expect(fieldKeys.contains("photo"))
    }
  }
}

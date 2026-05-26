//
//  CloudKitServiceTests.Rereference+Compose.swift
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
  @Suite("Rereference Asset Compose")
  internal struct Compose {
    private typealias Helper = CloudKitServiceTests.Rereference

    @Test("rereferenceAsset reuses the descriptor and returns the updated target")
    internal func reusesDescriptorOntoTarget() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }

      // rereference → reusable descriptor; lookup → target's type/changeTag;
      // modify → the saved target now carrying the same asset checksum.
      let service = try Helper.makeService(responsesByOperation: [
        "rereferenceAssets": try Helper.rereferenceResponse(assets: [
          Helper.assetDictionary(fileChecksum: "shared-chk")
        ]),
        "lookupRecords": try Helper.recordsResponse([
          Helper.noteRecord(recordName: "note-b", changeTag: "tag-b")
        ]),
        "modifyRecords": try Helper.recordsResponse([
          Helper.noteRecord(
            recordName: "note-b", changeTag: "tag-b2", imageChecksum: "shared-chk"
          )
        ]),
      ])

      let updated = try await service.rereferenceAsset(
        fromRecord: "note-a",
        field: "image",
        toRecord: "note-b",
        database: Helper.publicDatabase
      )

      #expect(updated.recordName == "note-b")
      guard case .asset(let asset) = updated.fields["image"] else {
        Issue.record("Updated target should carry an image asset")
        return
      }
      #expect(asset.fileChecksum == "shared-chk")
    }
  }
}

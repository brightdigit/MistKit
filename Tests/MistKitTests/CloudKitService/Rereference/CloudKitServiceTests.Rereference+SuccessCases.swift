//
//  CloudKitServiceTests.Rereference+SuccessCases.swift
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
  @Suite("Rereference Assets")
  internal struct SuccessCases {
    private typealias Helper = CloudKitServiceTests.Rereference

    @Test("rereferenceAssets maps asset descriptors in order")
    internal func mapsSuccessfulDescriptors() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Helper.makeService(responsesByOperation: [
        "rereferenceAssets": try Helper.rereferenceResponse(assets: [
          Helper.assetDictionary(fileChecksum: "chk-1"),
          Helper.assetDictionary(fileChecksum: "chk-2"),
        ])
      ])

      let assets = try await service.rereferenceAssets(
        [
          (recordName: "note-a", fieldName: "image"),
          (recordName: "note-b", fieldName: "image"),
        ],
        database: Helper.publicDatabase
      )

      #expect(assets.count == 2)
      let first = try #require(assets.first)
      #expect(first.fileChecksum == "chk-1")
      #expect(first.referenceChecksum == "ref-chk-1")
      #expect(first.wrappingKey == "wk-chk-1")
      #expect(first.receipt == "rcpt-chk-1")
      #expect(first.size == 1_024)
      #expect(first.downloadURL == "https://cvws.icloud-content.com/asset")
      #expect(assets.last?.fileChecksum == "chk-2")
    }

    @Test("rereferenceAssets throws on a top-level BAD_REQUEST")
    internal func throwsOnTopLevelFailure() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      // The live service fails the whole request (HTTP 400) when a source
      // record is missing, rather than returning a per-item error.
      let service = try Helper.makeService(responsesByOperation: [
        "rereferenceAssets": .cloudKitError(
          statusCode: 400,
          serverErrorCode: "BAD_REQUEST",
          reason: "record to rereference does not exist"
        )
      ])

      let error = await #expect(throws: CloudKitError.self) {
        _ = try await service.rereferenceAssets(
          [(recordName: "missing-rec", fieldName: "image")],
          database: Helper.publicDatabase
        )
      }
      guard case .badRequest(let reason) = error else {
        Issue.record("Expected .badRequest, got \(String(describing: error))")
        return
      }
      #expect(reason == "record to rereference does not exist")
    }
  }
}

//
//  CloudKitServiceTests.Sharing.swift
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

internal import Foundation
internal import Testing

@testable import MistKit

extension CloudKitServiceTests.Sharing {
  @Suite(
    "CloudKitService share-record key mapping",
    .enabled(if: Platform.isCryptoAvailable)
  )
  internal struct ShareInfoMapping {
    private typealias Helper = CloudKitServiceTests.Sharing

    @Test("resolveShares lifts share keys off the cloudkit.share record")
    internal func resolveLiftsShareInfo() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Helper.makeService(responsesByOperation: [
        "resolveShortGUIDs": try Helper.shortGUIDResponse(results: [
          Helper.shortGUIDResult(value: "guid-1")
        ])
      ])

      let result = try #require(
        try await service.resolveShares([ShortGUID(value: "guid-1")]).first
      )
      let shareInfo = try #require(result.shareInfo)
      #expect(shareInfo.shortGUID == "guid-1")
      #expect(shareInfo.publicPermission == .readOnly)
      #expect(shareInfo.participants.count == 1)
      let participant = try #require(shareInfo.participants.first)
      #expect(participant.permission == .readWrite)
      #expect(participant.type == .owner)
      #expect(participant.acceptanceStatus == .accepted)
      #expect(participant.userIdentity.userRecordName == .recordName("_owner"))
    }

    @Test("incomplete share record fails conversion with shareIncomplete")
    internal func incompleteShareThrows() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      // A `share` entry that looks like a share type but omits required keys.
      let service = try Helper.makeService(responsesByOperation: [
        "resolveShortGUIDs": try Helper.shortGUIDResponse(results: [
          [
            "shortGUID": ["value": "guid-1"],
            "share": [
              "recordName": "share-guid-1",
              "recordType": ShareInfo.recordType,
              "fields": [:],
            ],
          ]
        ])
      ])

      await ConversionFailureReporter.$assertionHandler.withValue(
        { _, _, _ in },
        operation: {
          await #expect(throws: CloudKitError.self) {
            _ = try await service.resolveShares([ShortGUID(value: "guid-1")])
          }
        }
      )
    }
  }
}

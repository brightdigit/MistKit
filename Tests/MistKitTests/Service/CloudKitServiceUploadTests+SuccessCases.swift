//
//  CloudKitServiceUploadTests+SuccessCases.swift
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

import Foundation
import Testing

@testable import MistKit

extension CloudKitServiceUploadTests {
  @Suite("Success Cases")
  internal struct SuccessCases {
    @Test("uploadAssets() successfully uploads valid asset")
    internal func uploadAssetsSuccessfullyUploadsValidAsset() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceUploadTests.makeSuccessfulUploadService(tokenCount: 1)
      let testData = Data(count: 1_024)  // 1 KB of test data

      let result = try await service.uploadAssets(
        data: testData,
        recordType: "Note",
        fieldName: "image",
        using: CloudKitServiceUploadTests.makeMockAssetUploader()
      )

      #expect(result.recordName.isEmpty == false, "Result should have a record name")
      #expect(result.fieldName == "file", "Result should have the field name from mock response")
      #expect(result.asset.receipt != nil, "Asset should have a receipt from CloudKit")
    }

    @Test("uploadAssets() parses single token from response")
    internal func uploadAssetsParseSingleToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceUploadTests.makeSuccessfulUploadService(tokenCount: 1)
      let testData = Data(count: 2_048)

      let result = try await service.uploadAssets(
        data: testData,
        recordType: "Note",
        fieldName: "image",
        using: CloudKitServiceUploadTests.makeMockAssetUploader()
      )

      #expect(result.recordName == "test-record-0")
      #expect(result.fieldName == "file")
      #expect(result.asset.receipt != nil)
    }

    @Test("uploadAssets() returns a single token")
    internal func uploadAssetsReturnsSingleToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceUploadTests.makeSuccessfulUploadService(tokenCount: 1)
      let testData = Data(count: 4_096)

      let result = try await service.uploadAssets(
        data: testData,
        recordType: "Note",
        fieldName: "image",
        using: CloudKitServiceUploadTests.makeMockAssetUploader()
      )

      #expect(result.recordName == "test-record-0")
      #expect(result.fieldName == "file")
      #expect(result.asset.receipt != nil)
    }

    @Test("requestAssetUploadURL() returns token with url, recordName, and fieldName")
    internal func requestAssetUploadURLReturnsToken() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceUploadTests.makeSuccessfulUploadService(tokenCount: 1)

      let token = try await service.requestAssetUploadURL(
        recordType: "Note",
        fieldName: "image"
      )

      #expect(token.url?.isEmpty == false)
      #expect(token.recordName == "test-record-0")
      #expect(token.fieldName == "file")
    }

    @Test("uploadAssets() invokes injected AssetUploader closure, not URLSession.shared")
    internal func uploadAssetsInvokesInjectedUploader() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceUploadTests.makeSuccessfulUploadService(tokenCount: 1)

      actor CallTracker {
        private(set) var callCount = 0
        func record() { callCount += 1 }
      }
      let tracker = CallTracker()

      let trackingUploader: AssetUploader = { data, _ in
        await tracker.record()
        let response = """
          {
            "singleFile": {
              "wrappingKey": "key",
              "fileChecksum": "cs",
              "receipt": "rcpt",
              "referenceChecksum": "rcs",
              "size": \(data.count)
            }
          }
          """
        return (200, Data(response.utf8))
      }

      _ = try await service.uploadAssets(
        data: Data(count: 1_024),
        recordType: "Note",
        fieldName: "image",
        using: trackingUploader
      )

      let count = await tracker.callCount
      #expect(count == 1, "Custom uploader should have been called exactly once")
    }
  }
}

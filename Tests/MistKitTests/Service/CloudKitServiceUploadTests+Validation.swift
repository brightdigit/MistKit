//
//  CloudKitServiceUploadTests+Validation.swift
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
  @Suite("Validation")
  internal struct Validation {
    @Test("uploadAssets() validates empty data")
    internal func uploadAssetsValidatesEmptyData() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceUploadTests.makeUploadValidationErrorService(
        .emptyData)

      do {
        _ = try await service.uploadAssets(
          data: Data(),
          recordType: "Note",
          fieldName: "image"
        )
        Issue.record("Expected error for empty data")
      } catch let error as CloudKitError {
        // Verify we get the correct validation error
        if case .httpErrorWithRawResponse(let statusCode, let response) = error {
          #expect(statusCode == 400)
          #expect(response.contains("Asset data cannot be empty"))
        } else {
          Issue.record("Expected httpErrorWithRawResponse error")
        }
      } catch {
        Issue.record("Expected CloudKitError, got \(type(of: error))")
      }
    }

    @Test("uploadAssets() validates 15 MB size limit", .disabled(if: Platform.isWasm))
    internal func uploadAssetsValidates15MBLimit() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      // Create data just over 15 MB (15 * 1024 * 1024 + 1 bytes)
      let oversizedData = Data(count: 15_728_641)
      let service = try await CloudKitServiceUploadTests.makeUploadValidationErrorService(
        .oversizedAsset(oversizedData.count)
      )

      do {
        _ = try await service.uploadAssets(
          data: oversizedData,
          recordType: "Note",
          fieldName: "image"
        )
        Issue.record("Expected error for oversized asset")
      } catch let error as CloudKitError {
        // Verify we get the correct validation error
        if case .httpErrorWithRawResponse(let statusCode, let response) = error {
          #expect(statusCode == 413)
          #expect(response.contains("exceeds maximum"))
        } else {
          Issue.record("Expected httpErrorWithRawResponse error, got \(error)")
        }
      } catch {
        Issue.record("Expected CloudKitError, got \(type(of: error))")
      }
    }

    @Test("uploadAssets() accepts valid data sizes", .disabled(if: Platform.isWasm))
    internal func uploadAssetsAcceptsValidSizes() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try await CloudKitServiceUploadTests.makeSuccessfulUploadService()

      // Test various valid sizes (CloudKit limit is 15 MB)
      let validSizes = [
        1,  // 1 byte
        1_024,  // 1 KB
        1_024 * 1_024,  // 1 MB
        10 * 1_024 * 1_024,  // 10 MB
        15 * 1_024 * 1_024,  // Exactly 15 MB (maximum allowed)
      ]

      for size in validSizes {
        let data = Data(count: size)
        do {
          let result = try await service.uploadAssets(
            data: data,
            recordType: "Note",
            fieldName: "image",
            using: CloudKitServiceUploadTests.makeMockAssetUploader()
          )
          #expect(result.asset.receipt != nil, "Should receive asset with receipt")
        } catch {
          Issue.record("Valid size \(size) bytes should not throw error: \(error)")
        }
      }
    }
  }
}

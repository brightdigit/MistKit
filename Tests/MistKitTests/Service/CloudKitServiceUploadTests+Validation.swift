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
      let service = try CloudKitServiceUploadTests.makeUploadValidationErrorService(.emptyData)

      do {
        _ = try await service.uploadAssets(data: Data())
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

    @Test("uploadAssets() validates 250 MB size limit")
    internal func uploadAssetsValidates250MBLimit() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      // Create data just over 250 MB (250 * 1024 * 1024 + 1 bytes)
      let oversizedData = Data(count: 262_144_001)
      let service = try CloudKitServiceUploadTests.makeUploadValidationErrorService(
        .oversizedAsset(oversizedData.count)
      )

      do {
        _ = try await service.uploadAssets(data: oversizedData)
        Issue.record("Expected error for oversized asset")
      } catch let error as CloudKitError {
        // Verify we get the correct validation error
        if case .httpErrorWithRawResponse(let statusCode, let response) = error {
          #expect(statusCode == 400)
          #expect(response.contains("exceeds maximum allowed size"))
          #expect(response.contains("250 MB"))
        } else {
          Issue.record("Expected httpErrorWithRawResponse error, got \(error)")
        }
      } catch {
        Issue.record("Expected CloudKitError, got \(type(of: error))")
      }
    }

    @Test("uploadAssets() accepts valid data sizes")
    internal func uploadAssetsAcceptsValidSizes() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceUploadTests.makeSuccessfulUploadService()

      // Test various valid sizes
      let validSizes = [
        1,  // 1 byte
        1024,  // 1 KB
        1024 * 1024,  // 1 MB
        10 * 1024 * 1024,  // 10 MB
        100 * 1024 * 1024,  // 100 MB
        250 * 1024 * 1024  // Exactly 250 MB (maximum allowed)
      ]

      for size in validSizes {
        let data = Data(count: size)
        do {
          let result = try await service.uploadAssets(data: data)
          #expect(result.tokens.count >= 1, "Should receive at least one upload token")
        } catch {
          Issue.record("Valid size \(size) bytes should not throw error: \(error)")
        }
      }
    }
  }
}

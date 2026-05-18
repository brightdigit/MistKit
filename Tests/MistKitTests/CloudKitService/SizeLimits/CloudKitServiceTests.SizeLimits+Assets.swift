//
//  CloudKitServiceTests.SizeLimits+Assets.swift
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

extension CloudKitServiceTests.SizeLimits {
  @Suite("Assets")
  internal struct Assets {
    private static func makeService() throws -> CloudKitService {
      let provider = ResponseProvider(defaultResponse: .success())
      return try CloudKitService(
        containerIdentifier: TestConstants.serviceContainerIdentifier,
        credentials: Credentials(apiAuth: APICredentials(apiToken: TestConstants.apiToken)),
        transport: MockTransport(responseProvider: provider)
      )
    }

    /// Uploader that always returns the given (status, body) so we can
    /// simulate a CDN-side 413 without involving the network.
    private static func failingUploader(
      status: Int,
      body: Data = Data()
    ) -> AssetUploader {
      { _, _ in (status, body) }
    }

    @Test(
      "uploadAssetData enriches 413 with assetExceedsSizeLimit when data is over 15 MB",
      .disabled(if: Platform.isWasm))
    internal func assetHintAttachedOnOversizedData() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Self.makeService()
      let oversized = Data(count: CloudKitService.maxAssetUploadBytes + 1)
      let url = try #require(URL(string: "https://cvws.icloud-content.com/test"))

      await #expect {
        _ = try await service.uploadAssetData(
          oversized,
          to: url,
          using: Self.failingUploader(status: 413)
        )
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .quotaExceeded(_, let hint) = ckError,
          case .assetExceedsSizeLimit(let bytes, let max) = hint
        else { return false }
        return bytes == oversized.count && max == CloudKitService.maxAssetUploadBytes
      }
    }

    @Test(
      "uploadAssetData passes 413 through unenriched when data is within the 15 MB limit",
      .disabled(if: Platform.isWasm))
    internal func assetHintNilWhenDataSmall() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Self.makeService()
      let withinLimit = Data(count: 1_024)
      let url = try #require(URL(string: "https://cvws.icloud-content.com/test"))

      await #expect {
        _ = try await service.uploadAssetData(
          withinLimit,
          to: url,
          using: Self.failingUploader(status: 413)
        )
      } throws: { error in
        guard let ckError = error as? CloudKitError else { return false }
        // No quota hint should be attached — the bare 413 propagates as-is.
        if case .quotaExceeded(_, let hint) = ckError, hint != nil {
          return false
        }
        return ckError.httpStatusCode == 413
      }
    }
  }
}

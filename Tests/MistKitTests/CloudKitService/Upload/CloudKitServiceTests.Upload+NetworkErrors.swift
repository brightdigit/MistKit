//
//  CloudKitServiceTests.Upload+NetworkErrors.swift
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

extension CloudKitServiceTests.Upload {
  @Suite("Network Errors")
  internal struct NetworkErrors {
    @Test("uploadAssets() surfaces a CloudKit-API timeout as networkError(.timedOut)")
    internal func uploadAssetsPropagatesAPITimeout() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try CloudKitServiceTests.makeService(provider: ResponseProvider.timeout())
      let testData = Data(count: 1_024)

      await #expect {
        _ = try await service.uploadAssets(
          data: testData,
          recordType: "Note",
          fieldName: "image",
          database: .public(.prefers(.serverToServer))
        )
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .networkError(let urlError) = ckError
        else { return false }
        return urlError.code == .timedOut
      }
    }

    @Test("uploadAssets() surfaces a CDN network failure thrown by a custom uploader")
    internal func uploadAssetsPropagatesCDNNetworkError() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      // CloudKit API returns a valid upload token, but the CDN upload throws.
      let provider = ResponseProvider.successfulUpload()
      let service = try CloudKitServiceTests.makeService(provider: provider)
      let testData = Data(count: 1_024)
      let throwingUploader: AssetUploader = { _, _ in
        throw URLError(.networkConnectionLost)
      }

      await #expect {
        _ = try await service.uploadAssets(
          data: testData,
          recordType: "Note",
          fieldName: "image",
          using: throwingUploader,
          database: .public(.prefers(.serverToServer))
        )
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .networkError(let urlError) = ckError
        else { return false }
        return urlError.code == .networkConnectionLost
      }
    }

    @Test("uploadAssets() surfaces a CDN 421 Misdirected Request as httpError")
    internal func uploadAssetsPropagatesCDN421() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let provider = ResponseProvider.successfulUpload()
      let service = try CloudKitServiceTests.makeService(provider: provider)
      let testData = Data(count: 1_024)
      let misdirectedUploader: AssetUploader = { _, _ in
        (statusCode: 421, data: Data("misdirected".utf8))
      }

      await #expect {
        _ = try await service.uploadAssets(
          data: testData,
          recordType: "Note",
          fieldName: "image",
          using: misdirectedUploader,
          database: .public(.prefers(.serverToServer))
        )
      } throws: { error in
        guard let ckError = error as? CloudKitError,
          case .httpError(let statusCode) = ckError
        else { return false }
        return statusCode == 421
      }
    }
  }
}

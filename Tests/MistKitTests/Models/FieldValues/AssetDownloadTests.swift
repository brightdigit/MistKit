//
//  AssetDownloadTests.swift
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

#if !os(WASI)
  internal import Foundation
  internal import Testing

  @testable import MistKit

  #if canImport(FoundationNetworking)
    internal import FoundationNetworking
  #endif

  @Suite("Asset Download")
  internal struct AssetDownloadTests {
    private static let plaintext = Data("hello".utf8)
    private static let opaqueChecksum = "AUStEc+gPyq1KTFbGO3RbXVpusut"
    private static let downloadURLString = "https://cvws.icloud-content.com/asset.bin"

    private static func httpResponse(statusCode: Int, url: URL) throws -> HTTPURLResponse {
      guard
        let response = HTTPURLResponse(
          url: url,
          statusCode: statusCode,
          httpVersion: nil,
          headerFields: nil
        )
      else {
        throw URLError(.badServerResponse)
      }
      return response
    }

    @Test("download throws httpError on a non-success status")
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    internal func downloadThrowsOnHTTPFailure() async throws {
      let asset = Asset(
        fileChecksum: Self.opaqueChecksum,
        downloadURL: Self.downloadURLString
      )
      let error = await #expect(throws: CloudKitError.self) {
        _ = try await asset.download { url in
          (Data(), try Self.httpResponse(statusCode: 404, url: url))
        }
      }
      guard case .httpError(let statusCode) = error else {
        Issue.record("Expected httpError, got \(error)")
        return
      }
      #expect(statusCode == 404)
    }

    @Test("download returns bytes without checking the opaque fileChecksum")
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    internal func downloadReturnsBytesWithoutChecksumCheck() async throws {
      // A real server-minted fileChecksum: a version byte plus a 20-byte
      // digest, not derivable from the plaintext. Downloads must not gate on it.
      let asset = Asset(
        fileChecksum: "AUStEc+gPyq1KTFbGO3RbXVpusut",
        downloadURL: Self.downloadURLString
      )
      let data = try await asset.download { url in
        (Self.plaintext, try Self.httpResponse(statusCode: 200, url: url))
      }
      #expect(data == Self.plaintext)
    }

    @Test("download returns bytes when the asset has no checksum")
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    internal func downloadReturnsBytesWhenChecksumMissing() async throws {
      let asset = Asset(downloadURL: Self.downloadURLString)
      let data = try await asset.download { url in
        (Self.plaintext, try Self.httpResponse(statusCode: 200, url: url))
      }
      #expect(data == Self.plaintext)
    }

    @Test("download throws missingAssetDownloadURL when the URL is absent")
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    internal func downloadThrowsWhenURLMissing() async throws {
      let asset = Asset(fileChecksum: Self.opaqueChecksum)
      let error = await #expect(throws: CloudKitError.self) {
        _ = try await asset.download { _ in
          Issue.record("fetch should not run when downloadURL is missing")
          throw URLError(.badURL)
        }
      }
      guard case .missingAssetDownloadURL = error else {
        Issue.record("Expected missingAssetDownloadURL, got \(error)")
        return
      }
    }

    @Test("download throws missingAssetDownloadURL when the URL is invalid")
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    internal func downloadThrowsWhenURLInvalid() async throws {
      let asset = Asset(
        fileChecksum: Self.opaqueChecksum,
        downloadURL: "not a url"
      )
      let error = await #expect(throws: CloudKitError.self) {
        _ = try await asset.download { _ in
          Issue.record("fetch should not run when downloadURL is invalid")
          throw URLError(.badURL)
        }
      }
      guard case .missingAssetDownloadURL = error else {
        Issue.record("Expected missingAssetDownloadURL, got \(error)")
        return
      }
    }
  }
#endif

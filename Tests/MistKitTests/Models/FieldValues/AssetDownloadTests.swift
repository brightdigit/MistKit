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

  @Suite("Asset Download", .serialized)
  internal struct AssetDownloadTests {
    private static let plaintext = Data("hello".utf8)
    private static let sha256Base64 = "LPJNul+wow4m6DsqxbninhsWHlwfp0JecwQzYpOLmCQ="
    private static let downloadURLString = "https://cvws.icloud-content.com/asset.bin"

    @Test("download returns bytes when HTTP succeeds and the checksum matches")
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    internal func downloadReturnsVerifiedBytes() async throws {
      let session = Self.sessionResponding(statusCode: 200, body: Self.plaintext)
      defer { MockURLProtocol.requestHandler = nil }

      let asset = Asset(
        fileChecksum: Self.sha256Base64,
        downloadURL: Self.downloadURLString
      )
      let data = try await asset.download(using: session)
      #expect(data == Self.plaintext)
    }

    @Test("download throws httpError on a non-success status")
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    internal func downloadThrowsOnHTTPFailure() async throws {
      let session = Self.sessionResponding(statusCode: 404, body: Data())
      defer { MockURLProtocol.requestHandler = nil }

      let asset = Asset(
        fileChecksum: Self.sha256Base64,
        downloadURL: Self.downloadURLString
      )
      let error = await #expect(throws: CloudKitError.self) {
        _ = try await asset.download(using: session)
      }
      guard case .httpError(let statusCode) = error else {
        Issue.record("Expected httpError, got \(error)")
        return
      }
      #expect(statusCode == 404)
    }

    @Test("download throws assetChecksumMismatch and does not return the body")
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    internal func downloadThrowsOnChecksumMismatch() async throws {
      let session = Self.sessionResponding(statusCode: 200, body: Data("world".utf8))
      defer { MockURLProtocol.requestHandler = nil }

      let asset = Asset(
        fileChecksum: Self.sha256Base64,
        downloadURL: Self.downloadURLString
      )
      let error = await #expect(throws: CloudKitError.self) {
        _ = try await asset.download(using: session)
      }
      guard case .assetChecksumMismatch = error else {
        Issue.record("Expected assetChecksumMismatch, got \(error)")
        return
      }
    }

    @Test("download throws missingAssetChecksum instead of returning unverified bytes")
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    internal func downloadThrowsWhenChecksumMissing() async throws {
      let session = Self.sessionResponding(statusCode: 200, body: Self.plaintext)
      defer { MockURLProtocol.requestHandler = nil }

      let asset = Asset(downloadURL: Self.downloadURLString)
      let error = await #expect(throws: CloudKitError.self) {
        _ = try await asset.download(using: session)
      }
      guard case .missingAssetChecksum = error else {
        Issue.record("Expected missingAssetChecksum, got \(error)")
        return
      }
    }

    @Test("download throws missingAssetDownloadURL when the URL is absent")
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    internal func downloadThrowsWhenURLMissing() async throws {
      let asset = Asset(fileChecksum: Self.sha256Base64)
      let error = await #expect(throws: CloudKitError.self) {
        _ = try await asset.download(using: MockURLProtocol.makeSession())
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
        fileChecksum: Self.sha256Base64,
        downloadURL: "not a url"
      )
      let error = await #expect(throws: CloudKitError.self) {
        _ = try await asset.download(using: MockURLProtocol.makeSession())
      }
      guard case .missingAssetDownloadURL = error else {
        Issue.record("Expected missingAssetDownloadURL, got \(error)")
        return
      }
    }

    private static func sessionResponding(statusCode: Int, body: Data) -> URLSession {
      MockURLProtocol.requestHandler = { request in
        let url = request.url ?? URL(fileURLWithPath: "/")
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
        return (response, body)
      }
      return MockURLProtocol.makeSession()
    }
  }
#endif

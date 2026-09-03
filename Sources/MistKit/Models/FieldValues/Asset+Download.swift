//
//  Asset+Download.swift
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

public import Foundation

#if canImport(FoundationNetworking)
  public import FoundationNetworking
#endif

#if !os(WASI)
  @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
  extension Asset {
    /// Downloads this asset's bytes and verifies them against ``fileChecksum``.
    ///
    /// Never returns unverified data. A missing ``fileChecksum`` is an error,
    /// not a skip. CDN `wrappingKey` encryption is out of scope.
    ///
    /// - Parameter session: Session used for the GET. Defaults to `.shared`,
    ///   matching CDN asset uploads (a connection pool separate from the
    ///   CloudKit API transport).
    /// - Returns: The response body after a successful checksum comparison.
    /// - Throws: ``CloudKitError/missingAssetDownloadURL`` when ``downloadURL``
    ///   is missing or not a valid URL; ``CloudKitError/httpError(statusCode:)``
    ///   on a non-success HTTP status; ``CloudKitError/missingAssetChecksum``
    ///   when ``fileChecksum`` is absent; ``CloudKitError/assetChecksumMismatch``
    ///   when the body does not match.
    public func download(using session: URLSession = .shared) async throws -> Data {
      let url = try resolvedDownloadURL()
      let (data, response) = try await session.data(from: url)
      try Self.requireSuccess(response)
      try requireMatchingChecksum(data)
      return data
    }

    private func resolvedDownloadURL() throws -> URL {
      guard let downloadURL, !downloadURL.isEmpty else {
        throw CloudKitError.missingAssetDownloadURL
      }
      guard let url = URL(string: downloadURL), url.host != nil else {
        throw CloudKitError.missingAssetDownloadURL
      }
      return url
    }

    private static func requireSuccess(_ response: URLResponse) throws {
      let statusCode = (response as? HTTPURLResponse)?.statusCode
      guard let statusCode else {
        throw CloudKitError.invalidResponse
      }
      guard (200...299).contains(statusCode) else {
        throw CloudKitError.httpError(statusCode: statusCode)
      }
    }

    private func requireMatchingChecksum(_ data: Data) throws {
      guard fileChecksum != nil else {
        throw CloudKitError.missingAssetChecksum
      }
      guard matches(data: data) else {
        throw CloudKitError.assetChecksumMismatch
      }
    }
  }
#endif

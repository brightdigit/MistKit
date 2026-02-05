//
//  URLSession+AssetUpload.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
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
  extension URLSession {
    /// Upload asset data directly to CloudKit CDN
    ///
    /// Returns the raw HTTP response without decoding. CloudKitService handles JSON decoding.
    ///
    /// - Parameters:
    ///   - data: Binary data to upload
    ///   - url: CloudKit CDN upload URL
    /// - Returns: Tuple containing optional HTTP status code and response data
    /// - Throws: Error if upload fails
    public func upload(_ data: Data, to url: URL) async throws -> (statusCode: Int?, data: Data) {
      // Create URLRequest for direct upload to CDN
      let request = URLRequest(forAssetUpload: data, to: url)

      // Upload directly via URLSession
      let (responseData, response) = try await self.data(for: request)

      let statusCode = (response as? HTTPURLResponse)?.statusCode
      return (statusCode, responseData)
    }
  }
#endif

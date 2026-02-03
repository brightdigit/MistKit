//
//  URLSession+AssetUpload.swift
//  MistKit
//
//  Created by Claude on 2026-02-02.
//

public import Foundation
#if canImport(FoundationNetworking)
public import FoundationNetworking
#endif

#if !os(WASI)
extension URLRequest {
  /// Initialize URLRequest for CloudKit asset upload
  /// - Parameters:
  ///   - data: Binary asset data to upload
  ///   - url: CloudKit CDN upload URL
  internal init(forAssetUpload data: Data, to url: URL) {
    self.init(url: url)
    self.httpMethod = "POST"
    self.httpBody = data
    self.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
  }
}

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

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
    public func uploadAsset(_ data: Data, to url: URL) async throws -> (statusCode: Int?, data: Data) {
        // Create URLRequest for direct upload to CDN
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

        // Upload directly via URLSession
        let (responseData, response) = try await self.data(for: request)

        let statusCode = (response as? HTTPURLResponse)?.statusCode
        return (statusCode, responseData)
    }
}
#endif

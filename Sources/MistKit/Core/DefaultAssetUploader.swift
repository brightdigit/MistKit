//
//  DefaultAssetUploader.swift
//  MistKit
//
//  Created by Claude on 2026-02-02.
//

import Foundation
import OpenAPIRuntime

#if !os(WASI)
/// Default asset uploader using URLSession directly
///
/// Uses a dedicated URLSession instance for CDN uploads to avoid HTTP/2
/// connection reuse issues between api.apple-cloudkit.com and
/// CloudKit's CDN (cvws.icloud-content.com).
internal struct DefaultAssetUploader: AssetUploader {
    private let urlSession: URLSession

    /// Initialize with a dedicated URLSession for CDN uploads
    /// - Parameter urlSession: URLSession instance for CDN domain (defaults to .shared)
    internal init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func uploadAsset(_ data: Data, to url: URL) async throws(CloudKitError) -> FieldValue.Asset {
        try await urlSession.uploadAsset(data, to: url)
    }
}
#endif

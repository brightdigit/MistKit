//
//  AssetUploader.swift
//  MistKit
//
//  Created by Claude on 2026-02-02.
//

public import Foundation
import HTTPTypes

/// Protocol for uploading binary asset data to CloudKit CDN
@available(*, deprecated, message: "Use AssetUploadHandler closure instead")
public protocol AssetUploader: Sendable {
    /// Upload binary data to a CloudKit asset URL
    /// - Parameters:
    ///   - data: Binary data to upload
    ///   - url: CloudKit CDN upload URL
    /// - Returns: Decoded asset metadata from CloudKit
    /// - Throws: CloudKitError if upload fails
    func uploadAsset(_ data: Data, to url: URL) async throws(CloudKitError) -> FieldValue.Asset
}

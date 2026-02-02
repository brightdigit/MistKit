//
//  MockAssetUploader.swift
//  MistKit
//
//  Created by Claude on 2026-02-02.
//

import Foundation
@testable import MistKit

internal actor MockAssetUploader: AssetUploader {
    internal var uploadedData: Data?
    internal var uploadedURL: URL?
    private let response: FieldValue.Asset

    internal init(response: FieldValue.Asset) {
        self.response = response
    }

    func uploadAsset(_ data: Data, to url: URL) async throws(CloudKitError) -> FieldValue.Asset {
        self.uploadedData = data
        self.uploadedURL = url
        return response
    }
}

//
//  WASIAssetUploader.swift
//  MistKit
//
//  Created by Claude on 2026-02-02.
//

import Foundation

#if os(WASI)
/// Placeholder asset uploader for WASI platform (not supported)
internal struct WASIAssetUploader: AssetUploader {
    internal init() {}

    func uploadAsset(_ data: Data, to url: URL) async throws(CloudKitError) -> FieldValue.Asset {
        throw CloudKitError.underlyingError(
            NSError(
                domain: "MistKit",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Asset upload not supported on WASI"]
            )
        )
    }
}
#endif

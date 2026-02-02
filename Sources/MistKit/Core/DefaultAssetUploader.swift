//
//  DefaultAssetUploader.swift
//  MistKit
//
//  Created by Claude on 2026-02-02.
//

import Foundation
import OpenAPIRuntime

#if !os(WASI)
/// Bridges ClientTransport to AssetUploader protocol
internal struct DefaultAssetUploader: AssetUploader {
    private let transport: any ClientTransport

    internal init(transport: any ClientTransport) {
        self.transport = transport
    }

    func uploadAsset(_ data: Data, to url: URL) async throws(CloudKitError) -> FieldValue.Asset {
        try await transport.uploadAsset(data, to: url)
    }
}
#endif

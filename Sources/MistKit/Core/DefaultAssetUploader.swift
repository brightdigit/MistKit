//
//  DefaultAssetUploader.swift
//  MistKit
//
//  Created by Claude on 2026-02-02.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import OpenAPIRuntime

#if !os(WASI)
/// Default asset uploader using URLSession directly
///
/// Uses a dedicated URLSession instance for CDN uploads to avoid HTTP/2
/// connection reuse issues between api.apple-cloudkit.com and
/// CloudKit's CDN (cvws.icloud-content.com).
@available(*, deprecated, message: "Use AssetUploadHandler closure instead")
internal struct DefaultAssetUploader: AssetUploader {
    private let urlSession: URLSession

    /// Initialize with a dedicated URLSession for CDN uploads
    /// - Parameter urlSession: URLSession instance for CDN domain (defaults to .shared)
    internal init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func uploadAsset(_ data: Data, to url: URL) async throws(CloudKitError) -> FieldValue.Asset {
        do {
            let (statusCode, responseData) = try await urlSession.uploadAsset(data, to: url)

            guard let statusCode = statusCode, (200...299).contains(statusCode) else {
                throw CloudKitError.httpError(statusCode: statusCode ?? 0)
            }

            // Decode the response
            struct AssetUploadResponse: Codable {
                let singleFile: AssetData
                struct AssetData: Codable {
                    let wrappingKey: String?
                    let fileChecksum: String?
                    let receipt: String?
                    let referenceChecksum: String?
                    let size: Int64?
                }
            }

            let uploadResponse = try JSONDecoder().decode(AssetUploadResponse.self, from: responseData)

            return FieldValue.Asset(
                fileChecksum: uploadResponse.singleFile.fileChecksum,
                size: uploadResponse.singleFile.size,
                referenceChecksum: uploadResponse.singleFile.referenceChecksum,
                wrappingKey: uploadResponse.singleFile.wrappingKey,
                receipt: uploadResponse.singleFile.receipt,
                downloadURL: nil
            )
        } catch let cloudKitError as CloudKitError {
            throw cloudKitError
        } catch let decodingError as DecodingError {
            throw CloudKitError.decodingError(decodingError)
        } catch {
            throw CloudKitError.underlyingError(error)
        }
    }
}
#endif

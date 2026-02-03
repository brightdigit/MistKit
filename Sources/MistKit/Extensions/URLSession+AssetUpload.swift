//
//  URLSession+AssetUpload.swift
//  MistKit
//
//  Created by Claude on 2026-02-02.
//

public import Foundation

#if !os(WASI)
// Response structure for CloudKit asset upload
// CloudKit returns: { "singleFile": { "wrappingKey": ..., "fileChecksum": ..., "receipt": ..., etc. } }
private struct AssetUploadResponse: Codable {
    let singleFile: AssetData

    struct AssetData: Codable {
        let wrappingKey: String?
        let fileChecksum: String?
        let receipt: String?
        let referenceChecksum: String?
        let size: Int64?
    }
}

extension URLSession {
    /// Upload asset data directly to CloudKit CDN
    ///
    /// Uses URLSession directly to avoid OpenAPI transport layer complications
    /// when uploading to a different host (CDN) than the API.
    ///
    /// - Parameters:
    ///   - data: Binary data to upload
    ///   - url: CloudKit CDN upload URL
    /// - Returns: Decoded asset metadata from CloudKit
    /// - Throws: CloudKitError if upload fails
    public func uploadAsset(_ data: Data, to url: URL) async throws(CloudKitError) -> FieldValue.Asset {
        do {
            // Create URLRequest for direct upload to CDN
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = data
            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

            // Upload directly via URLSession
            let (responseData, response) = try await self.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw CloudKitError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw CloudKitError.httpError(statusCode: httpResponse.statusCode)
            }

            // Debug: log the raw response
            if let responseString = String(data: responseData, encoding: .utf8) {
                MistKitLogger.logDebug(
                    "Asset upload response: \(responseString)",
                    logger: MistKitLogger.api,
                    shouldRedact: false
                )
            }

            let uploadResponse = try JSONDecoder().decode(AssetUploadResponse.self, from: responseData)

            // Convert to FieldValue.Asset
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
            MistKitLogger.logError(
                "Failed to decode asset upload response: \(decodingError)",
                logger: MistKitLogger.api,
                shouldRedact: false
            )
            throw CloudKitError.decodingError(decodingError)
        } catch {
            MistKitLogger.logError(
                "Error uploading asset data: \(error)",
                logger: MistKitLogger.network,
                shouldRedact: false
            )
            throw CloudKitError.underlyingError(error)
        }
    }
}
#endif

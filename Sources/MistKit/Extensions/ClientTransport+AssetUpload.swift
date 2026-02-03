//
//  ClientTransport+AssetUpload.swift
//  MistKit
//
//  Created by Claude on 2026-02-02.
//

public import Foundation
public import OpenAPIRuntime

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

extension ClientTransport {
    /// Default asset upload implementation using URLSession directly
    ///
    /// IMPORTANT: This uses URLSession.shared directly instead of the transport to avoid
    /// HTTP/2 connection reuse issues. The transport is connected to api.apple-cloudkit.com,
    /// but asset uploads go to CloudKit's CDN (cvws.icloud-content.com), causing 421
    /// "Misdirected Request" errors if we try to reuse the same connection.
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

            // Use URLSession directly to avoid HTTP/2 connection reuse issues
            let (responseData, response) = try await URLSession.shared.data(for: request)

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
                downloadURL: nil  // Download URL is provided by CloudKit when fetching the record later
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
            // General error handling
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

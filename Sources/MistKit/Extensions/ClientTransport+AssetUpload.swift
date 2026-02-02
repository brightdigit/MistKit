//
//  ClientTransport+AssetUpload.swift
//  MistKit
//
//  Created by Claude on 2026-02-02.
//

public import Foundation
import HTTPTypes
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
    /// Default asset upload implementation using the transport's send method
    /// - Parameters:
    ///   - data: Binary data to upload
    ///   - url: CloudKit CDN upload URL
    /// - Returns: Decoded asset metadata from CloudKit
    /// - Throws: CloudKitError if upload fails
    public func uploadAsset(_ data: Data, to url: URL) async throws(CloudKitError) -> FieldValue.Asset {
        do {
            // Parse URL components for HTTPRequest
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let scheme = components.scheme,
                  let host = components.host
            else {
                throw CloudKitError.invalidResponse
            }

            let authority = if let port = components.port {
                "\(host):\(port)"
            } else {
                host
            }

            // Build HTTPRequest
            var request = HTTPRequest(
                method: .post,
                scheme: scheme,
                authority: authority,
                path: components.path.isEmpty ? "/" : components.path
            )

            // Add Content-Type header
            request.headerFields[.contentType] = "application/octet-stream"

            // Create HTTPBody from data
            let body = HTTPBody(data)

            // Send the request
            let (httpResponse, responseBody) = try await self.send(
                request,
                body: body,
                baseURL: URL(string: "\(scheme)://\(authority)")!,
                operationID: "uploadAssetData"
            )

            guard (200...299).contains(httpResponse.status.code) else {
                throw CloudKitError.httpError(statusCode: httpResponse.status.code)
            }

            // Extract response data
            guard let responseBody = responseBody else {
                throw CloudKitError.invalidResponse
            }

            let responseData = try await Data(collecting: responseBody, upTo: .max)

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

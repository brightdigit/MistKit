//
//  CloudKitService+AssetOperations.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import Foundation
import HTTPTypes
import OpenAPIRuntime

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

#if !os(WASI)
  import OpenAPIURLSession
#endif

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
  /// Upload binary asset data to CloudKit
  ///
  /// This is a convenience method that performs a complete two-step
  /// asset upload:
  /// 1. Requests an upload URL from CloudKit
  /// 2. Uploads the binary data to that URL
  ///
  /// - Parameters:
  ///   - data: The binary data to upload
  ///   - recordType: The type of record that will use this asset
  ///   - fieldName: The name of the asset field
  ///   - recordName: Optional unique record name
  ///   - uploader: Optional custom upload handler
  /// - Returns: AssetUploadReceipt containing the upload result
  /// - Throws: CloudKitError if the upload fails
  ///
  /// Example:
  /// ```swift
  /// let imageData = try Data(contentsOf: imageURL)
  /// let token = try await service.uploadAssets(
  ///   data: imageData,
  ///   recordType: "Photo",
  ///   fieldName: "image"
  /// )
  /// ```
  ///
  /// - Note: Upload URLs are valid for 15 minutes
  /// - Warning: Maximum upload size is 15 MB per asset
  public func uploadAssets(
    data: Data,
    recordType: String,
    fieldName: String,
    recordName: String? = nil,
    using uploader: AssetUploader? = nil
  ) async throws(CloudKitError) -> AssetUploadReceipt {
    let maxSize: Int = 15 * 1_024 * 1_024
    guard data.count <= maxSize else {
      throw CloudKitError.httpErrorWithRawResponse(
        statusCode: 413,
        rawResponse:
          "Asset size \(data.count) exceeds maximum of \(maxSize) bytes"
      )
    }

    guard !data.isEmpty else {
      throw CloudKitError.httpErrorWithRawResponse(
        statusCode: 400,
        rawResponse: "Asset data cannot be empty"
      )
    }

    do {
      let urlToken = try await requestAssetUploadURL(
        recordType: recordType,
        fieldName: fieldName,
        recordName: recordName
      )

      guard let uploadURLString = urlToken.url,
        let uploadURL = URL(string: uploadURLString)
      else {
        throw CloudKitError.invalidResponse
      }

      let asset = try await uploadAssetData(
        data, to: uploadURL, using: uploader
      )

      return AssetUploadReceipt(
        asset: asset,
        recordName: urlToken.recordName ?? "unknown",
        fieldName: urlToken.fieldName ?? fieldName
      )
    } catch {
      throw mapToCloudKitError(error, context: "uploadAssets")
    }
  }

  /// Request an upload URL for an asset field
  ///
  /// This is step 1 of the two-step asset upload process.
  ///
  /// - Parameters:
  ///   - recordType: The type of record that will use this asset
  ///   - fieldName: The name of the asset field
  ///   - recordName: Optional unique record name
  ///   - zoneID: Optional zone ID (defaults to default zone)
  /// - Returns: AssetUploadToken containing the upload URL
  /// - Throws: CloudKitError if the request fails
  public func requestAssetUploadURL(
    recordType: String,
    fieldName: String,
    recordName: String? = nil,
    zoneID: ZoneID? = nil
  ) async throws(CloudKitError) -> AssetUploadToken {
    do {
      let tokenRequest =
        Operations.uploadAssets.Input.Body
        .jsonPayload.tokensPayloadPayload(
          recordName: recordName,
          recordType: recordType,
          fieldName: fieldName
        )

      let requestBody = Operations.uploadAssets.Input.Body.jsonPayload(
        zoneID: zoneID.map { Components.Schemas.ZoneID(from: $0) },
        tokens: [tokenRequest]
      )

      let response = try await client.uploadAssets(
        path: createUploadAssetsPath(
          containerIdentifier: containerIdentifier
        ),
        body: .json(requestBody)
      )

      let uploadData: Components.Schemas.AssetUploadResponse =
        try await responseProcessor.processUploadAssetsResponse(response)

      guard let token = uploadData.tokens?.first else {
        throw CloudKitError.invalidResponse
      }

      return AssetUploadToken(from: token)
    } catch let cloudKitError as CloudKitError {
      throw cloudKitError
    } catch {
      throw CloudKitError.underlyingError(error)
    }
  }

  /// Upload binary data to a CloudKit asset upload URL
  ///
  /// This is step 2 of the two-step asset upload process.
  ///
  /// - Parameters:
  ///   - data: The binary data to upload
  ///   - url: The upload URL from CloudKit
  ///   - uploader: Optional custom upload handler
  /// - Returns: The asset returned by CloudKit
  /// - Throws: CloudKitError if the upload fails
  /// - Note: Upload URLs are valid for 15 minutes
  public func uploadAssetData(
    _ data: Data,
    to url: URL,
    using uploader: AssetUploader? = nil
  ) async throws(CloudKitError) -> FieldValue.Asset {
    do {
      let uploadHandler =
        uploader ?? { data, url in
          #if os(WASI)
            throw CloudKitError.httpErrorWithRawResponse(
              statusCode: 501,
              rawResponse: "Asset uploads not supported on WASI"
            )
          #else
            return try await URLSession.shared.upload(data, to: url)
          #endif
        }

      let (statusCode, responseData) = try await uploadHandler(data, url)

      guard let httpStatusCode = statusCode else {
        throw CloudKitError.invalidResponse
      }
      guard (200...299).contains(httpStatusCode) else {
        throw CloudKitError.httpError(statusCode: httpStatusCode)
      }

      if let responseString = String(
        data: responseData, encoding: .utf8
      ) {
        MistKitLogger.logDebug(
          "Asset upload response: \(responseString)",
          logger: MistKitLogger.api,
          shouldRedact: false
        )
      }

      let uploadResponse = try JSONDecoder().decode(
        AssetUploadResponse.self, from: responseData
      )

      return FieldValue.Asset(
        fileChecksum: uploadResponse.singleFile.fileChecksum,
        size: uploadResponse.singleFile.size,
        referenceChecksum: uploadResponse.singleFile.referenceChecksum,
        wrappingKey: uploadResponse.singleFile.wrappingKey,
        receipt: uploadResponse.singleFile.receipt,
        downloadURL: nil
      )
    } catch {
      throw mapToCloudKitError(error, context: "uploadAssetData")
    }
  }
}

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
internal import MistKitOpenAPI
import OpenAPIRuntime

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

#if !os(WASI)
  import OpenAPIURLSession
#endif

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
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
  ///   - database: The CloudKit database scope to upload to (`.public`, `.private`, `.shared`)
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
    using uploader: AssetUploader? = nil,
    database: Database
  ) async throws(CloudKitError) -> AssetUploadReceipt {
    guard data.count <= Self.maxAssetUploadBytes else {
      throw CloudKitError.invalidArgument(
        parameter: "data",
        reason:
          "exceeds 15 MB CloudKit per-asset upload limit "
          + "(got \(data.count) bytes, max \(Self.maxAssetUploadBytes))"
      )
    }

    guard !data.isEmpty else {
      throw CloudKitError.invalidArgument(
        parameter: "data",
        reason: "must not be empty"
      )
    }

    do {
      let urlToken = try await requestAssetUploadURL(
        recordType: recordType,
        fieldName: fieldName,
        recordName: recordName,
        database: database
      )

      guard let uploadURL = urlToken.url else {
        throw CloudKitError.invalidResponse
      }

      let asset = try await uploadAssetData(
        data, to: uploadURL, using: uploader
      )

      guard let recordName = urlToken.recordName else {
        throw CloudKitError.invalidResponse
      }
      return AssetUploadReceipt(
        asset: asset,
        recordName: recordName,
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
  ///   - database: The CloudKit database scope (`.public`, `.private`, `.shared`)
  /// - Returns: AssetUploadToken containing the upload URL
  /// - Throws: CloudKitError if the request fails
  public func requestAssetUploadURL(
    recordType: String,
    fieldName: String,
    recordName: String? = nil,
    zoneID: ZoneID? = nil,
    database: Database
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

      let client = try self.client(for: database)
      let response = try await client.uploadAssets(
        path: Operations.uploadAssets.Input.Path(
          containerIdentifier: containerIdentifier,
          environment: environment,
          database: database
        ),
        body: .json(requestBody)
      )

      let uploadData: Components.Schemas.AssetUploadResponse =
        try await responseProcessor.processUploadAssetsResponse(response)

      guard let token = uploadData.tokens?.first else {
        throw CloudKitError.invalidResponse
      }

      return AssetUploadToken(from: token)
    } catch {
      throw mapToCloudKitError(error, context: "requestAssetUploadURL")
    }
  }
}

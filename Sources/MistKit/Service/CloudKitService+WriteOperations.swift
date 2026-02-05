//
//  CloudKitService+WriteOperations.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
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
  /// Modify (create, update, or delete) CloudKit records
  /// - Parameter operations: Array of record operations to perform
  /// - Returns: Array of RecordInfo for the modified records
  /// - Throws: CloudKitError if the operation fails
  public func modifyRecords(
    _ operations: [RecordOperation]
  ) async throws(CloudKitError) -> [RecordInfo] {
    do {
      // Convert public RecordOperation types to internal OpenAPI types
      let apiOperations = operations.map { Components.Schemas.RecordOperation(from: $0) }

      // Call the underlying OpenAPI client
      let response = try await client.modifyRecords(
        .init(
          path: .init(
            version: "1",
            container: containerIdentifier,
            environment: .init(from: environment),
            database: .init(from: database)
          ),
          body: .json(
            .init(
              operations: apiOperations,
              atomic: false  // Continue on individual failures
            )
          )
        )
      )

      // Process the response
      let modifyResponse: Components.Schemas.ModifyResponse =
        try await responseProcessor.processModifyRecordsResponse(response)

      // Convert response records to RecordInfo
      return modifyResponse.records?.compactMap { RecordInfo(from: $0) } ?? []
    } catch let cloudKitError as CloudKitError {
      throw cloudKitError
    } catch {
      // Preserve original error context
      throw CloudKitError.underlyingError(error)
    }
  }

  /// Create a single record in CloudKit
  /// - Parameters:
  ///   - recordType: The type of record to create (e.g., "RestoreImage")
  ///   - recordName: Optional unique record name (if nil, CloudKit will generate one)
  ///   - fields: Dictionary of field names to FieldValue
  /// - Returns: RecordInfo for the created record
  /// - Throws: CloudKitError if the operation fails
  public func createRecord(
    recordType: String,
    recordName: String? = nil,
    fields: [String: FieldValue]
  ) async throws(CloudKitError) -> RecordInfo {
    let operation = RecordOperation.create(
      recordType: recordType,
      recordName: recordName,
      fields: fields
    )

    let results = try await modifyRecords([operation])
    guard let record = results.first else {
      throw CloudKitError.invalidResponse
    }
    return record
  }

  /// Update a single record in CloudKit
  /// - Parameters:
  ///   - recordType: The type of record to update
  ///   - recordName: The unique record name
  ///   - fields: Dictionary of field names to FieldValue
  ///   - recordChangeTag: Optional change tag for optimistic locking
  /// - Returns: RecordInfo for the updated record
  /// - Throws: CloudKitError if the operation fails
  public func updateRecord(
    recordType: String,
    recordName: String,
    fields: [String: FieldValue],
    recordChangeTag: String? = nil
  ) async throws(CloudKitError) -> RecordInfo {
    let operation = RecordOperation.update(
      recordType: recordType,
      recordName: recordName,
      fields: fields,
      recordChangeTag: recordChangeTag
    )

    let results = try await modifyRecords([operation])
    guard let record = results.first else {
      throw CloudKitError.invalidResponse
    }
    return record
  }

  /// Delete a single record from CloudKit
  /// - Parameters:
  ///   - recordType: The type of record to delete
  ///   - recordName: The unique record name
  ///   - recordChangeTag: Optional change tag for optimistic locking
  /// - Throws: CloudKitError if the operation fails
  public func deleteRecord(
    recordType: String,
    recordName: String,
    recordChangeTag: String? = nil
  ) async throws(CloudKitError) {
    let operation = RecordOperation.delete(
      recordType: recordType,
      recordName: recordName,
      recordChangeTag: recordChangeTag
    )

    _ = try await modifyRecords([operation])
  }

  /// Upload binary asset data to CloudKit
  ///
  /// This is a convenience method that performs a complete two-step asset upload:
  /// 1. Requests an upload URL from CloudKit
  /// 2. Uploads the binary data to that URL
  ///
  /// - Parameters:
  ///   - data: The binary data to upload
  ///   - recordType: The type of record that will use this asset (e.g., "Photo")
  ///   - fieldName: The name of the asset field (e.g., "image")
  ///   - recordName: Optional unique record name (defaults to CloudKit-generated UUID)
  /// - Returns: AssetUploadToken containing the upload URL for record association
  /// - Throws: CloudKitError if the upload fails
  ///
  /// Example:
  /// ```swift
  /// // Upload the asset
  /// let imageData = try Data(contentsOf: imageURL)
  /// let token = try await service.uploadAssets(
  ///   data: imageData,
  ///   recordType: "Photo",
  ///   fieldName: "image"
  /// )
  ///
  /// // Create a record with the asset
  /// let asset = FieldValue.Asset(
  ///   fileChecksum: nil,
  ///   size: Int64(imageData.count),
  ///   referenceChecksum: nil,
  ///   wrappingKey: nil,
  ///   receipt: nil,
  ///   downloadURL: token.url
  /// )
  ///
  /// let record = try await service.createRecord(
  ///   recordType: "Photo",
  ///   fields: [
  ///     "image": .asset(asset),
  ///     "title": .string("My Photo")
  ///   ]
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
    // Validate data size (CloudKit limit is 15 MB)
    let maxSize: Int = 15 * 1_024 * 1_024  // 15 MB
    guard data.count <= maxSize else {
      throw CloudKitError.httpErrorWithRawResponse(
        statusCode: 413,
        rawResponse: "Asset size \(data.count) exceeds maximum of \(maxSize) bytes"
      )
    }

    guard !data.isEmpty else {
      throw CloudKitError.httpErrorWithRawResponse(
        statusCode: 400,
        rawResponse: "Asset data cannot be empty"
      )
    }

    do {
      // Step 1: Request upload URL
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

      // Step 2: Upload binary data to the URL and get asset dictionary
      let asset = try await uploadAssetData(data, to: uploadURL, using: uploader)

      // Return complete result with asset data
      return AssetUploadReceipt(
        asset: asset,
        recordName: urlToken.recordName ?? "unknown",
        fieldName: urlToken.fieldName ?? fieldName
      )
    } catch let cloudKitError as CloudKitError {
      throw cloudKitError
    } catch let decodingError as DecodingError {
      MistKitLogger.logError(
        "JSON decoding failed in uploadAssets: \(decodingError)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )
      throw CloudKitError.decodingError(decodingError)
    } catch let urlError as URLError {
      MistKitLogger.logError(
        "Network error in uploadAssets: \(urlError)",
        logger: MistKitLogger.network,
        shouldRedact: false
      )
      throw CloudKitError.networkError(urlError)
    } catch {
      MistKitLogger.logError(
        "Unexpected error in uploadAssets: \(error)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )
      throw CloudKitError.underlyingError(error)
    }
  }

  /// Request an upload URL for an asset field
  ///
  /// This is step 1 of the two-step asset upload process. Use `uploadAssetData(_:to:)`
  /// to complete step 2, or use the convenience method `uploadAssets(data:recordType:fieldName:)`
  /// to perform both steps.
  ///
  /// - Parameters:
  ///   - recordType: The type of record that will use this asset
  ///   - fieldName: The name of the asset field
  ///   - recordName: Optional unique record name (defaults to CloudKit-generated UUID)
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
      // Create token request
      let tokenRequest = Operations.uploadAssets.Input.Body.jsonPayload.tokensPayloadPayload(
        recordName: recordName,
        recordType: recordType,
        fieldName: fieldName
      )

      let requestBody = Operations.uploadAssets.Input.Body.jsonPayload(
        zoneID: zoneID.map { Components.Schemas.ZoneID(from: $0) },
        tokens: [tokenRequest]
      )

      let response = try await client.uploadAssets(
        path: createUploadAssetsPath(containerIdentifier: containerIdentifier),
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
  /// This is step 2 of the two-step asset upload process. Use `requestAssetUploadURL`
  /// to get the upload URL first, or use the convenience method
  /// `uploadAssets(data:recordType:fieldName:)` to perform both steps.
  ///
  /// - Parameters:
  ///   - data: The binary data to upload
  ///   - url: The upload URL from CloudKit
  ///   - uploader: Optional custom upload handler. If nil, uses URLSession.shared
  /// - Returns: The asset dictionary returned by CloudKit containing receipt, checksums, etc.
  /// - Throws: CloudKitError if the upload fails
  /// - Note: Upload URLs are valid for 15 minutes
  /// - Important: The returned asset dictionary must be used when creating/updating records with this asset
  public func uploadAssetData(
    _ data: Data,
    to url: URL,
    using uploader: AssetUploader? = nil
  ) async throws(CloudKitError) -> FieldValue.Asset {
    do {
      // Use provided uploader or default to URLSession.shared
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

      // Perform the upload
      let (statusCode, responseData) = try await uploadHandler(data, url)

      // Validate HTTP status code
      guard let httpStatusCode = statusCode else {
        throw CloudKitError.invalidResponse
      }
      guard (200...299).contains(httpStatusCode) else {
        throw CloudKitError.httpError(statusCode: httpStatusCode)
      }

      // Debug: log the raw response
      if let responseString = String(data: responseData, encoding: .utf8) {
        MistKitLogger.logDebug(
          "Asset upload response: \(responseString)",
          logger: MistKitLogger.api,
          shouldRedact: false
        )
      }

      // Decode the response
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
    } catch let urlError as URLError {
      MistKitLogger.logError(
        "Network error uploading asset: \(urlError)",
        logger: MistKitLogger.network,
        shouldRedact: false
      )
      throw CloudKitError.networkError(urlError)
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

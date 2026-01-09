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
import OpenAPIRuntime

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
  /// Uploads binary data (images, files, etc.) to CloudKit and returns tokens
  /// that can be used to associate the assets with record fields.
  ///
  /// This is a two-step process:
  /// 1. Upload the binary data using this method to get tokens
  /// 2. Create/update a record with the tokens in asset fields
  ///
  /// - Parameter data: The binary data to upload
  /// - Returns: AssetUploadResult containing tokens for record association
  /// - Throws: CloudKitError if the upload fails
  ///
  /// Example - Upload and Associate:
  /// ```swift
  /// // Step 1: Upload the asset
  /// let imageData = try Data(contentsOf: imageURL)
  /// let uploadResult = try await service.uploadAssets(data: imageData)
  ///
  /// guard let token = uploadResult.tokens.first else {
  ///   throw CloudKitError.invalidResponse
  /// }
  ///
  /// // Step 2: Create a record with the asset
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
  /// - Note: The uploaded data must be associated with a record field within
  ///         a reasonable time frame, or CloudKit may garbage collect it.
  /// - Warning: Maximum upload size is 250 MB per asset
  public func uploadAssets(data: Data) async throws(CloudKitError) -> AssetUploadResult {
    // Validate data size (CloudKit limit is 250 MB)
    let maxSize: Int = 250 * 1024 * 1024 // 250 MB
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
      // Create multipart body
      let filePayload = Operations.uploadAssets.Input.Body.multipartFormPayload.filePayload(
        body: OpenAPIRuntime.HTTPBody(data)
      )
      let filePart = OpenAPIRuntime.MultipartPart(
        payload: filePayload,
        filename: nil
      )
      let multipartParts: [Operations.uploadAssets.Input.Body.multipartFormPayload] = [
        .file(filePart)
      ]
      let multipartBody = OpenAPIRuntime.MultipartBody(multipartParts)

      let response = try await client.uploadAssets(
        path: createUploadAssetsPath(containerIdentifier: containerIdentifier),
        body: .multipartForm(multipartBody)
      )

      let uploadData: Components.Schemas.AssetUploadResponse =
        try await responseProcessor.processUploadAssetsResponse(response)

      return AssetUploadResult(from: uploadData)
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
}

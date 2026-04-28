//
//  CloudKitService+AssetUpload.swift
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

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

#if !os(WASI)
  import OpenAPIURLSession
#endif

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
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

//
//  AssetUploadResponse.swift
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

/// Response structure for CloudKit CDN asset upload
///
/// After uploading binary data to the CloudKit CDN, the server returns this structure
/// containing the asset metadata needed to associate the upload with a record field.
///
/// This type is useful when implementing custom upload workflows or when you need
/// to perform the upload steps individually rather than using the combined `uploadAssets()` method.
///
/// Response format: `{ "singleFile": { "wrappingKey": ..., "fileChecksum": ..., "receipt": ..., etc. } }`
public struct AssetUploadResponse: Codable, Sendable {
  /// The uploaded asset data containing checksums and receipt
  public let singleFile: AssetData

  /// Asset metadata returned from CloudKit CDN
  public struct AssetData: Codable, Sendable {
    /// Wrapping key for encrypted assets
    public let wrappingKey: String?
    /// SHA256 checksum of the uploaded file
    public let fileChecksum: String?
    /// Receipt token proving successful upload
    public let receipt: String?
    /// Reference checksum for asset verification
    public let referenceChecksum: String?
    /// Size of the uploaded asset in bytes
    public let size: Int64?

    /// Initialize asset data
    public init(
      wrappingKey: String?,
      fileChecksum: String?,
      receipt: String?,
      referenceChecksum: String?,
      size: Int64?
    ) {
      self.wrappingKey = wrappingKey
      self.fileChecksum = fileChecksum
      self.receipt = receipt
      self.referenceChecksum = referenceChecksum
      self.size = size
    }
  }

  /// Initialize asset upload response
  public init(singleFile: AssetData) {
    self.singleFile = singleFile
  }
}

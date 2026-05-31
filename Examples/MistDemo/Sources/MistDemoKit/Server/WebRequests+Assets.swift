//
//  WebRequests+Assets.swift
//  MistDemo
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

internal import Foundation
internal import MistKit

extension WebRequests {
  /// `POST /api/assets/upload`
  ///
  /// Upload binary asset data to CloudKit's CDN as the first half of an
  /// asset-bearing record write. The browser sends the bytes as a base64
  /// string in `data`; CloudKit returns a reusable `Asset` descriptor (plus
  /// the record name it bound the upload to) that the next
  /// `/api/records/create` call must reference.
  ///
  /// `recordName` is optional — when omitted CloudKit assigns a fresh one
  /// and echoes it back in the receipt, which the browser then forwards to
  /// the subsequent create.
  internal struct UploadAsset: Decodable {
    private enum CodingKeys: String, CodingKey {
      case recordType
      case fieldName
      case recordName
      case data
      case database
    }

    internal let recordType: String
    internal let fieldName: String
    internal let recordName: String?
    internal let data: Data
    internal let database: MistKit.Database

    internal init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.recordType = try container.decode(String.self, forKey: .recordType)
      self.fieldName = try container.decode(String.self, forKey: .fieldName)
      self.recordName = try container.decodeIfPresent(
        String.self, forKey: .recordName
      )
      self.data = try container.decode(Data.self, forKey: .data)
      self.database = try WebRequests.decodeDatabase(
        from: container, forKey: .database
      )
    }
  }

  /// `POST /api/assets/rereference`
  ///
  /// Mirrors CloudKit Web Services `assets/rereference`: re-reference an
  /// asset that already lives on a source record onto a target record's
  /// asset field, sharing the same underlying bytes without re-uploading.
  /// The server composes `assets/rereference` + `records/modify` via
  /// `CloudKitService.rereferenceAsset(fromRecord:field:toRecord:field:)`,
  /// matching the CloudKit JS fetch-source-then-save-target flow.
  ///
  /// `targetAssetField` is optional — when omitted the source `assetField`
  /// name is reused on the target, the same default as the Swift API.
  internal struct RereferenceAsset: Decodable {
    private enum CodingKeys: String, CodingKey {
      case sourceRecordName
      case assetField
      case targetRecordName
      case targetAssetField
      case database
    }

    internal let sourceRecordName: String
    internal let assetField: String
    internal let targetRecordName: String
    internal let targetAssetField: String?
    internal let database: MistKit.Database

    internal init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.sourceRecordName =
        try container.decode(String.self, forKey: .sourceRecordName)
      self.assetField = try container.decode(String.self, forKey: .assetField)
      self.targetRecordName =
        try container.decode(String.self, forKey: .targetRecordName)
      self.targetAssetField = try container.decodeIfPresent(
        String.self, forKey: .targetAssetField
      )
      self.database = try WebRequests.decodeDatabase(
        from: container, forKey: .database
      )
    }
  }
}

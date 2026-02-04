//
//  AssetUploadToken.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

/// Token returned after uploading an asset
///
/// After uploading binary data, CloudKit returns tokens that must be
/// associated with record fields using a subsequent modifyRecords operation.
public struct AssetUploadToken: Sendable, Equatable {
  /// The upload URL (may be used for download reference)
  public let url: String?
  /// The record name this token is associated with
  public let recordName: String?
  /// The field name this token should be assigned to
  public let fieldName: String?

  /// Initialize an asset upload token
  public init(url: String?, recordName: String?, fieldName: String?) {
    self.url = url
    self.recordName = recordName
    self.fieldName = fieldName
  }

  internal init(from token: Components.Schemas.AssetUploadResponse.tokensPayloadPayload) {
    self.url = token.url
    self.recordName = token.recordName
    self.fieldName = token.fieldName
  }
}

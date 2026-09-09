//
//  ShareTargetReference.swift
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

internal import MistKitOpenAPI

/// Identifies the root record being shared when creating a `cloudkit.share`
/// record (CloudKit's `forRecord` key).
public struct ShareTargetReference: Codable, Sendable, Equatable, Hashable {
  /// The record name of the shared root record.
  public let recordName: String
  /// Optional change tag for optimistic concurrency when creating the share.
  public let recordChangeTag: String?

  /// Initialize a share target reference.
  /// - Parameters:
  ///   - recordName: The record name of the shared root record.
  ///   - recordChangeTag: Optional change tag for the root record.
  public init(recordName: String, recordChangeTag: String? = nil) {
    self.recordName = recordName
    self.recordChangeTag = recordChangeTag
  }
}

extension Components.Schemas.ShareTargetReference {
  internal init(from reference: ShareTargetReference) {
    self.init(
      recordName: reference.recordName,
      recordChangeTag: reference.recordChangeTag
    )
  }
}

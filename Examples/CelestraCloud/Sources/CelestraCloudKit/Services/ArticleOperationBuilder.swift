//
//  ArticleOperationBuilder.swift
//  CelestraCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

public import CelestraKit
public import Foundation
public import MistKit

/// Pure function type for building CloudKit record operations from articles.
/// Follows the pattern of ArticleCategorizer and FeedMetadataBuilder for testable,
/// dependency-free operation building.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public struct ArticleOperationBuilder: Sendable {
  /// Initialize article operation builder
  public init() {}

  /// Build create operations from articles
  /// - Parameter articles: Articles to create (recordName will be generated)
  /// - Returns: Array of create operations, one per article
  public func buildCreateOperations(_ articles: [Article]) -> [RecordOperation] {
    articles.map { article in
      RecordOperation.create(
        recordType: "Article",
        recordName: UUID().uuidString,
        fields: article.toFieldsDict()
      )
    }
  }

  /// Build update operations from articles
  /// - Parameter articles: Articles to update (must have recordName)
  /// - Returns: Tuple of (operations, skipped count)
  ///   - operations: Update operations for valid articles
  ///   - skipped: Count of articles without recordName
  public func buildUpdateOperations(_ articles: [Article])
    -> (operations: [RecordOperation], skipped: Int)
  {
    var skipped = 0
    let operations = articles.compactMap { article -> RecordOperation? in
      guard let recordName = article.recordName else {
        skipped += 1
        return nil
      }

      return RecordOperation.update(
        recordType: "Article",
        recordName: recordName,
        fields: article.toFieldsDict(),
        recordChangeTag: article.recordChangeTag
      )
    }

    return (operations, skipped)
  }

  /// Build delete operations from record info
  /// - Parameter records: Record info from query results
  /// - Returns: Array of delete operations
  public func buildDeleteOperations(_ records: [RecordInfo]) -> [RecordOperation] {
    records.map { record in
      RecordOperation.delete(
        recordType: "Article",
        recordName: record.recordName,
        recordChangeTag: record.recordChangeTag
      )
    }
  }
}

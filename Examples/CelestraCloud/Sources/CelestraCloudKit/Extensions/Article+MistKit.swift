//
//  Article+MistKit.swift
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

extension Article: CloudKitConvertible {
  // MARK: - Initializers

  /// Create Article from MistKit RecordInfo using shared parsing helpers.
  ///
  /// - Parameter record: The CloudKit RecordInfo containing field data.
  /// - Throws: `CloudKitConversionError.missingRequiredField` if required fields are missing.
  public init(from record: RecordInfo) throws {
    let feedRecordName = try record.requiredString(forKey: "feedRecordName", recordType: "Article")
    let guid = try record.requiredString(forKey: "guid", recordType: "Article")
    let title = try record.requiredString(forKey: "title", recordType: "Article")
    let url = try record.requiredString(forKey: "url", recordType: "Article")
    let excerpt = record.optionalString(forKey: "excerpt")
    let content = record.optionalString(forKey: "content")
    let contentText = record.optionalString(forKey: "contentText")
    let author = record.optionalString(forKey: "author")
    let imageURL = record.optionalString(forKey: "imageURL")
    let language = record.optionalString(forKey: "language")
    let publishedDate = record.optionalDate(forKey: "publishedTimestamp")
    let fetchedAt = record.date(forKey: "fetchedTimestamp", default: Date())
    let expiresAt = record.optionalDate(forKey: "expiresTimestamp")
    let ttlDays = Self.calculateTTLDays(fetchedAt: fetchedAt, expiresAt: expiresAt)
    let wordCount = record.optionalInt(forKey: "wordCount")
    let estimatedReadingTime = record.optionalInt(forKey: "estimatedReadingTime")
    let tags = record.stringArray(forKey: "tags")

    self.init(
      recordName: record.recordName,
      recordChangeTag: record.recordChangeTag,
      feedRecordName: feedRecordName,
      guid: guid,
      title: title,
      excerpt: excerpt,
      content: content,
      contentText: contentText,
      author: author,
      url: url,
      imageURL: imageURL,
      publishedDate: publishedDate,
      fetchedAt: fetchedAt,
      ttlDays: ttlDays,
      wordCount: wordCount,
      estimatedReadingTime: estimatedReadingTime,
      language: language,
      tags: tags
    )
  }

  // MARK: - Type Methods

  private static func calculateTTLDays(fetchedAt: Date, expiresAt: Date?) -> Int {
    guard let expiresAt = expiresAt else {
      return 30
    }
    let interval = expiresAt.timeIntervalSince(fetchedAt)
    return max(1, Int(interval / (24 * 60 * 60)))
  }

  // MARK: - Instance Methods

  /// Convert to CloudKit record fields dictionary using MistKit's FieldValue.
  ///
  /// - Returns: Dictionary mapping field names to FieldValue instances.
  public func toFieldsDict() -> [String: FieldValue] {
    var fields: [String: FieldValue] = [
      "feedRecordName": .string(feedRecordName),
      "guid": .string(guid),
      "title": .string(title),
      "url": .string(url),
      "fetchedTimestamp": .date(fetchedAt),
      "expiresTimestamp": .date(expiresAt),
      "contentHash": .string(contentHash),
    ]

    addOptionalString(&fields, key: "excerpt", value: excerpt)
    addOptionalString(&fields, key: "content", value: content)
    addOptionalString(&fields, key: "contentText", value: contentText)
    addOptionalString(&fields, key: "author", value: author)
    addOptionalString(&fields, key: "imageURL", value: imageURL)
    addOptionalString(&fields, key: "language", value: language)
    addOptionalDate(&fields, key: "publishedTimestamp", value: publishedDate)
    addOptionalInt(&fields, key: "wordCount", value: wordCount)
    addOptionalInt(&fields, key: "estimatedReadingTime", value: estimatedReadingTime)

    if !tags.isEmpty {
      fields["tags"] = .list(tags.map { .string($0) })
    }

    return fields
  }

  // MARK: - Private Helpers

  private func addOptionalString(
    _ fields: inout [String: FieldValue],
    key: String,
    value: String?
  ) {
    if let value = value {
      fields[key] = .string(value)
    }
  }

  private func addOptionalDate(
    _ fields: inout [String: FieldValue],
    key: String,
    value: Date?
  ) {
    if let value = value {
      fields[key] = .date(value)
    }
  }

  private func addOptionalInt(
    _ fields: inout [String: FieldValue],
    key: String,
    value: Int?
  ) {
    if let value = value {
      fields[key] = .int64(value)
    }
  }
}

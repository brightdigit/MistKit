//
//  Feed+MistKit.swift
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

extension Feed: CloudKitConvertible {
  // swiftlint:disable function_body_length
  /// Create Feed from MistKit RecordInfo using shared parsing helpers.
  ///
  /// - Parameter record: The CloudKit RecordInfo containing field data.
  /// - Throws: `CloudKitConversionError.missingRequiredField` if feedURL or title is missing.
  public init(from record: RecordInfo) throws {
    let feedURL = try record.requiredString(forKey: "feedURL", recordType: "Feed")
    let title = try record.requiredString(forKey: "title", recordType: "Feed")
    let description = record.optionalString(forKey: "description")
    let category = record.optionalString(forKey: "category")
    let imageURL = record.optionalString(forKey: "imageURL")
    let siteURL = record.optionalString(forKey: "siteURL")
    let language = record.optionalString(forKey: "language")
    let etag = record.optionalString(forKey: "etag")
    let lastModified = record.optionalString(forKey: "lastModified")
    let lastFailureReason = record.optionalString(forKey: "lastFailureReason")
    let isFeatured = record.bool(forKey: "isFeatured")
    let isVerified = record.bool(forKey: "isVerified")
    let isActive = record.bool(forKey: "isActive", default: true)
    let qualityScore = record.int(forKey: "qualityScore", default: 50)
    let subscriberCount = record.int64(forKey: "subscriberCount")
    let totalAttempts = record.int64(forKey: "totalAttempts")
    let successfulAttempts = record.int64(forKey: "successfulAttempts")
    let failureCount = record.int64(forKey: "failureCount")
    let addedAt = record.date(forKey: "createdTimestamp", default: Date())
    let lastVerified = record.optionalDate(forKey: "verifiedTimestamp")
    let lastAttempted = record.optionalDate(forKey: "attemptedTimestamp")
    let updateFrequency = record.optionalDouble(forKey: "updateFrequency")
    let minUpdateInterval = record.optionalDouble(forKey: "minUpdateInterval")
    let tags = record.stringArray(forKey: "tags")

    self.init(
      recordName: record.recordName,
      recordChangeTag: record.recordChangeTag,
      feedURL: feedURL,
      title: title,
      description: description,
      category: category,
      imageURL: imageURL,
      siteURL: siteURL,
      language: language,
      isFeatured: isFeatured,
      isVerified: isVerified,
      qualityScore: qualityScore,
      subscriberCount: subscriberCount,
      addedAt: addedAt,
      lastVerified: lastVerified,
      updateFrequency: updateFrequency,
      tags: tags,
      totalAttempts: totalAttempts,
      successfulAttempts: successfulAttempts,
      lastAttempted: lastAttempted,
      isActive: isActive,
      etag: etag,
      lastModified: lastModified,
      failureCount: failureCount,
      lastFailureReason: lastFailureReason,
      minUpdateInterval: minUpdateInterval
    )
  }
  // swiftlint:enable function_body_length

  /// Convert to CloudKit record fields dictionary using MistKit's FieldValue.
  ///
  /// - Returns: Dictionary mapping field names to FieldValue instances.
  public func toFieldsDict() -> [String: FieldValue] {
    var fields: [String: FieldValue] = [
      "feedURL": .string(feedURL),
      "title": .string(title),
      "isFeatured": .int64(isFeatured ? 1 : 0),
      "isVerified": .int64(isVerified ? 1 : 0),
      "qualityScore": .int64(qualityScore),
      "subscriberCount": .int64(Int(subscriberCount)),
      "totalAttempts": .int64(Int(totalAttempts)),
      "successfulAttempts": .int64(Int(successfulAttempts)),
      "isActive": .int64(isActive ? 1 : 0),
      "failureCount": .int64(Int(failureCount)),
    ]

    // Optional string fields
    addOptionalString(&fields, key: "description", value: description)
    addOptionalString(&fields, key: "category", value: category)
    addOptionalString(&fields, key: "imageURL", value: imageURL)
    addOptionalString(&fields, key: "siteURL", value: siteURL)
    addOptionalString(&fields, key: "language", value: language)
    addOptionalString(&fields, key: "etag", value: etag)
    addOptionalString(&fields, key: "lastModified", value: lastModified)
    addOptionalString(&fields, key: "lastFailureReason", value: lastFailureReason)

    // Optional date fields
    addOptionalDate(&fields, key: "verifiedTimestamp", value: lastVerified)
    addOptionalDate(&fields, key: "attemptedTimestamp", value: lastAttempted)

    // Optional numeric fields
    addOptionalDouble(&fields, key: "updateFrequency", value: updateFrequency)
    addOptionalDouble(&fields, key: "minUpdateInterval", value: minUpdateInterval)

    // Array fields
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

  private func addOptionalDouble(
    _ fields: inout [String: FieldValue],
    key: String,
    value: Double?
  ) {
    if let value = value {
      fields[key] = .double(value)
    }
  }
}

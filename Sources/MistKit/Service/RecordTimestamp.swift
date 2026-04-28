//
//  RecordTimestamp.swift
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

public import Foundation

/// Timestamp information for record creation or modification
public struct RecordTimestamp: Encodable, Sendable {
  /// The date when the action occurred
  public let timestamp: Date?
  /// The record name of the user who performed the action
  public let userRecordName: String?

  internal init(from schema: Components.Schemas.RecordTimestamp) {
    self.timestamp = schema.timestamp.flatMap { millis in
      guard millis >= 0 else { return nil }
      return Date(timeIntervalSince1970: millis / 1000.0)
    }
    self.userRecordName = schema.userRecordName
  }

  /// Public initializer for creating RecordTimestamp instances
  ///
  /// - Parameters:
  ///   - timestamp: The date when the action occurred
  ///   - userRecordName: The record name of the user who performed the action
  public init(timestamp: Date? = nil, userRecordName: String? = nil) {
    self.timestamp = timestamp
    self.userRecordName = userRecordName
  }
}

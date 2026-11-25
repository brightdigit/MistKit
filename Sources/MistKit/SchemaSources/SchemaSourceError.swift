//
//  SchemaSourceError.swift
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

/// Why a ``SchemaSource`` couldn't load a schema, other than an error from
/// CloudKit (``CloudKitError``, ``CloudKitManagementError``) or the schema
/// text itself (``SchemaParseError``).
public enum SchemaSourceError: LocalizedError, Sendable {
  /// The file couldn't be read. `underlying` is the error reading it threw.
  case unreadableFile(URL, underlying: any Error)
  /// The file isn't UTF-8 text.
  case notUTF8(URL)
  /// An ``InferredSchemaSource`` was given no record types to query.
  case noRecordTypes

  /// A description naming the file, if there is one.
  public var errorDescription: String? {
    switch self {
    case .unreadableFile(let url, let underlying):
      "Couldn't read \(url.lastPathComponent): \(underlying.localizedDescription)"
    case .notUTF8(let url):
      "\(url.lastPathComponent) isn't UTF-8 text"
    case .noRecordTypes:
      "No record types to infer a schema from"
    }
  }
}

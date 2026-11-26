//
//  CloudKitSchema+ContentsOf.swift
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

extension CloudKitSchema {
  /// Reads and parses a CloudKit Schema Language file, such as a `.ckdb` file
  /// `cktool export-schema` wrote.
  ///
  /// - Parameter url: A file URL.
  /// - Throws: ``SchemaSourceError/unreadableFile(_:underlying:)`` when the
  ///   file can't be read, ``SchemaSourceError/notUTF8(_:)`` when it isn't
  ///   UTF-8 text, and ``SchemaParseError`` when it isn't a valid schema.
  public init(contentsOf url: URL) throws {
    let data: Data
    do {
      data = try Data(contentsOf: url)
    } catch {
      throw SchemaSourceError.unreadableFile(url, underlying: error)
    }
    try self.init(data: data, from: url)
  }

  /// Parses file contents read from `url`.
  internal init(data: Data, from url: URL) throws {
    guard let text = String(data: data, encoding: .utf8) else {
      throw SchemaSourceError.notUTF8(url)
    }
    try self.init(parsing: text)
  }
}

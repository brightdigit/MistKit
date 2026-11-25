//
//  CloudKitSchema+Writing.swift
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

internal import Foundation

extension CloudKitSchema {
  private static let indent = "    "

  /// The schema as CloudKit Schema Language text that ``init(parsing:)`` reads
  /// back to an equal schema.
  ///
  /// The layout follows `cktool export-schema`: `DEFINE SCHEMA`, roles before
  /// record types, a blank line before each declaration, four-space indents,
  /// field types aligned in a column, index options in the order `QUERYABLE`
  /// `SEARCHABLE` `SORTABLE`, then one grant per line. Names are quoted when
  /// they must be (``writtenIdentifier(_:)``). Comments aren't kept; CloudKit
  /// doesn't keep them either. The text ends with a newline.
  public var schemaText: String {
    written().text
  }

  /// A name as the language writes it: bare when it starts with an ASCII
  /// letter, continues with ASCII letters, digits or `_`, and isn't a reserved
  /// word (`GRANT`, `PREFERRED`, `QUERYABLE`, `SORTABLE`, `SEARCHABLE`);
  /// otherwise in double quotes.
  public static func writtenIdentifier(_ name: String) -> String {
    needsQuotes(name) ? "\"\(name)\"" : name
  }

  private static func needsQuotes(_ name: String) -> Bool {
    guard let first = name.first, first.isASCII, first.isLetter else {
      return true
    }
    let isValid = name.allSatisfy {
      $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_")
    }
    return !isValid || SchemaParser.reservedWords.contains(name.uppercased())
  }

  /// This schema with each record type's and field's ``SchemaRecordType/sourceLine``
  /// set to its line in ``schemaText``.
  public func annotatingSourceLines() -> CloudKitSchema {
    written().schema
  }

  private func written() -> (text: String, schema: CloudKitSchema) {
    var lines = ["DEFINE SCHEMA"]
    var annotated = self
    for role in roles {
      lines += ["", "\(Self.indent)CREATE ROLE \(Self.writtenIdentifier(role));"]
    }
    for (typeIndex, recordType) in recordTypes.enumerated() {
      lines.append("")
      annotated.recordTypes[typeIndex].sourceLine = lines.count + 1
      for fieldIndex in recordType.fields.indices {
        annotated.recordTypes[typeIndex].fields[fieldIndex].sourceLine =
          lines.count + 2 + fieldIndex
      }
      lines += recordType.schemaLines(indent: Self.indent)
    }
    return (lines.joined(separator: "\n") + "\n", annotated)
  }
}

extension SchemaRecordType {
  fileprivate func schemaLines(indent: String) -> [String] {
    let nameWidth =
      (fields.map { CloudKitSchema.writtenIdentifier($0.name).count }.max() ?? 0) + 2
    let elements =
      fields.map { $0.schemaText(nameWidth: nameWidth) } + grants.map(\.schemaText)
    let body = elements.enumerated().map { offset, element in
      indent + indent + element + (offset < elements.count - 1 ? "," : "")
    }
    let name = CloudKitSchema.writtenIdentifier(self.name)
    return ["\(indent)RECORD TYPE \(name) ("] + body + ["\(indent));"]
  }
}

extension SchemaField {
  /// The field as one line of the language, without indent or comma, such as
  /// `"___recordID" REFERENCE QUERYABLE`.
  public var schemaText: String {
    schemaText(nameWidth: 0)
  }

  fileprivate func schemaText(nameWidth: Int) -> String {
    let name = CloudKitSchema.writtenIdentifier(self.name)
    let padding = String(repeating: " ", count: max(1, nameWidth - name.count))
    var options: [String] = []
    if isQueryable {
      options.append("QUERYABLE")
    }
    if isSearchable {
      options.append("SEARCHABLE")
    }
    if isSortable {
      options.append("SORTABLE")
    }
    return ([name + padding + type.schemaText] + options).joined(separator: " ")
  }
}

extension SchemaGrant {
  /// The grant as the language writes it, such as `GRANT READ, WRITE TO "_creator"`.
  public var schemaText: String {
    let list = permissions.map(\.rawValue).joined(separator: ", ")
    return "GRANT \(list) TO \(CloudKitSchema.writtenIdentifier(role))"
  }
}

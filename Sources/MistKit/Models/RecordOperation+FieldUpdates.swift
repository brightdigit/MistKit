//
//  RecordOperation+FieldUpdates.swift
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

extension RecordOperation {
  /// Creates an operation whose field changes are one map, where `nil` clears
  /// a field.
  ///
  /// Each non-`nil` value goes into ``fields``; each `nil` name goes into
  /// ``clearedFields`` and is sent as `{"value": null}`. Use it when the
  /// changes come from an editor that tracks "set" and "cleared" together.
  ///
  /// ```swift
  /// let operation = RecordOperation(
  ///   operationType: .update,
  ///   recordType: "Note",
  ///   recordName: "n-1",
  ///   fieldUpdates: ["title": .string(.value("Hi")), "body": nil],
  ///   recordChangeTag: tag
  /// )
  /// // fields == ["title": …], clearedFields == ["body"]
  /// ```
  ///
  /// - Parameters:
  ///   - operationType: The operation to perform.
  ///   - recordType: The record type.
  ///   - recordName: The record name; `nil` lets CloudKit name a created record.
  ///   - fieldUpdates: Field values to write; `nil` clears the field.
  ///   - encryptedFields: Field names to send with `isEncrypted: true`.
  ///   - recordChangeTag: The change tag the operation is checked against.
  public init(
    operationType: OperationType,
    recordType: String,
    recordName: String?,
    fieldUpdates: [String: FieldValue?],
    encryptedFields: Set<String> = [],
    recordChangeTag: String? = nil
  ) {
    var fields: [String: FieldValue] = [:]
    var clearedFields: Set<String> = []
    for (name, value) in fieldUpdates {
      if let value {
        fields[name] = value
      } else {
        clearedFields.insert(name)
      }
    }
    self.init(
      operationType: operationType,
      recordType: recordType,
      recordName: recordName,
      fields: fields,
      clearedFields: clearedFields,
      encryptedFields: encryptedFields,
      recordChangeTag: recordChangeTag
    )
  }
}

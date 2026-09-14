//
//  RecordOperation+EncryptedFields.swift
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

extension RecordOperation {
  /// Reject encrypted-field writes that CloudKit (and MistKit) cannot honor
  /// before the request leaves the client.
  ///
  /// - Public database: encrypted fields are private/shared only.
  /// - Reference and asset values: Apple documents encryption for scalar and
  ///   list field types declared `ENCRYPTED` in the schema, not references or
  ///   assets via `isEncrypted` on the field dictionary.
  internal func validateEncryptedFields(
    for database: Database
  ) throws(CloudKitError) {
    guard !encryptedFields.isEmpty else {
      return
    }

    if case .public = database {
      throw CloudKitError.badRequest(
        reason:
          "Encrypted fields are only supported on private and shared databases"
      )
    }

    for fieldName in encryptedFields {
      try validateEncryptedField(named: fieldName)
    }
  }

  /// Verify a single encrypted field names a value MistKit can mark encrypted.
  private func validateEncryptedField(
    named fieldName: String
  ) throws(CloudKitError) {
    guard let value = fields[fieldName] else {
      throw CloudKitError.badRequest(
        reason:
          "encryptedFields contains '\(fieldName)' which is not present in fields"
      )
    }

    switch value {
    case .reference:
      // Matches `.reference(.value)` *and* `.reference(.list)`. Since #481 a list of
      // references is exactly `.reference(.list)`, so this one arity-free pattern also
      // rejects the encrypted-list-of-references case the pre-Arity `case .list` let
      // through — heterogeneous lists are unrepresentable, so there are no members to
      // walk.
      throw CloudKitError.badRequest(
        reason: "Reference fields cannot be marked encrypted ('\(fieldName)')"
      )
    case .asset:
      // Same reasoning; CloudKit encrypts assets on its own and rejects the flag.
      throw CloudKitError.badRequest(
        reason: "Asset fields cannot be marked encrypted ('\(fieldName)')"
      )
    case .string, .int64, .double, .bytes, .date, .location:
      break
    }
  }
}

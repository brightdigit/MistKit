//
//  CKRecord+TypedField.swift
//  MistDemo
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

#if canImport(CloudKit)
  import CloudKit
  import Foundation

  extension CKRecord {
    /// Reads `field` from the record and casts it to `T`.
    ///
    /// Returns `nil` when the field is absent — that's a normal optional
    /// field. When the field is present but holds a value of the wrong
    /// type, this triggers `assertionFailure` (debug-only crash) before
    /// returning `nil`. A type mismatch indicates a schema/code drift
    /// that should be caught loudly during development.
    internal func typedValue<T>(
      forField field: String,
      as _: T.Type = T.self
    ) -> T? {
      guard let raw = self[field] else {
        return nil
      }
      guard let typed = raw as? T else {
        assertionFailure(
          "CKRecord field '\(field)' on record type '\(recordType)' "
            + "expected \(T.self) but got \(Swift.type(of: raw)) "
            + "(value: \(raw))"
        )
        return nil
      }
      return typed
    }
  }
#endif

//
//  WireFields.swift
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
internal import MistKitOpenAPI

/// A record's `fields` dictionary in CloudKit Web Services JSON: the set,
/// cleared (`{"value": null}`) and encrypted (`"isEncrypted": true`) fields.
///
/// Shared by ``WireRecord`` and ``WireRecordOperation``. Fields are written
/// sorted by name.
internal struct WireFields: Hashable, Sendable {
  private struct EncryptedFlag: Decodable {
    let isEncrypted: Bool?
  }

  /// The set fields.
  internal var values: [String: FieldValue]
  /// Field names written as `{"value": null}`.
  internal var cleared: Set<String>
  /// Field names written with `"isEncrypted": true`.
  internal var encrypted: Set<String>
  /// When field dictionaries carry `type`. Decoding sets
  /// ``FieldTypeTagging/always`` when any field had a `type`.
  internal var typeTagging: FieldTypeTagging

  internal init(
    values: [String: FieldValue] = [:],
    cleared: Set<String> = [],
    encrypted: Set<String> = [],
    typeTagging: FieldTypeTagging = .whenRequired
  ) {
    self.values = values
    self.cleared = cleared
    self.encrypted = encrypted
    self.typeTagging = typeTagging
  }

  /// Decodes the `fields` dictionary at `key`; none when the key is absent.
  internal init<Key: CodingKey>(
    from container: KeyedDecodingContainer<Key>,
    forKey key: Key
  ) throws {
    self.init()
    guard container.contains(key), try !container.decodeNil(forKey: key) else {
      return
    }
    let fields = try container.nestedContainer(keyedBy: WireFieldKey.self, forKey: key)
    for name in fields.allKeys {
      let field = try fields.decode(WireFieldValue.self, forKey: name)
      if field.typeTagging == .always {
        typeTagging = .always
      }
      if let value = field.value {
        values[name.stringValue] = value
      } else {
        cleared.insert(name.stringValue)
      }
      if try fields.decode(EncryptedFlag.self, forKey: name).isEncrypted == true {
        encrypted.insert(name.stringValue)
      }
    }
  }

  /// Encodes the `fields` dictionary at `key`, sorted by field name.
  ///
  /// A name in both ``values`` and ``cleared`` is written with its value.
  /// The dictionary is encoded as a value, not through a nested container, so
  /// an `EncodingError` (a number that isn't finite) has `key` and the field
  /// name in its coding path; `JSONEncoder` leaves a nested container's key
  /// out.
  internal func encode<Key: CodingKey>(
    to container: inout KeyedEncodingContainer<Key>,
    forKey key: Key
  ) throws {
    try container.encode(self, forKey: key)
  }
}

extension WireFields: Encodable {
  /// Encodes the `fields` dictionary, sorted by field name.
  internal func encode(to encoder: any Encoder) throws {
    var fields = encoder.container(keyedBy: WireFieldKey.self)
    for name in Set(values.keys).union(cleared).sorted() {
      let field = WireFieldValue(values[name], typeTagging: typeTagging)
      try fields.encode(
        field.request(isEncrypted: encrypted.contains(name)),
        forKey: WireFieldKey(stringValue: name)
      )
    }
  }
}

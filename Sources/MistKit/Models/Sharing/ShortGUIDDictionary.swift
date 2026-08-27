//
//  ShortGUIDDictionary.swift
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

internal import MistKitOpenAPI

/// Opaque short-GUID token string as returned by CloudKit.
///
/// Appears as a bare string on record / share payloads. The resolve and
/// accept request/result dictionary shape is ``ShortGUIDDictionary``.
public typealias ShortGUID = String

/// CloudKit's ShortGUID Dictionary — a short GUID plus optional root-fetch
/// options used by `records/resolve` and `records/accept`.
///
/// CloudKit assigns a short GUID to a record when it is shared — either
/// explicitly, by setting `createShortGUID` when creating the record, or
/// implicitly, when a `cloudkit.share` record is created for it. The GUID
/// value is what a share URL carries; this dictionary wraps that value with
/// knobs for resolve/accept.
public struct ShortGUIDDictionary: Codable, Sendable, Equatable, Hashable {
  /// The value of the short global ID.
  public let value: ShortGUID
  /// Whether the root record should be fetched alongside the share.
  ///
  /// When `nil`, CloudKit applies its own default.
  public let shouldFetchRootRecord: Bool?
  /// Field names limiting the data returned in the root record.
  ///
  /// When `nil`, every field of the root record is returned.
  public let rootRecordDesiredKeys: [String]?

  /// Initialize a short GUID dictionary.
  /// - Parameters:
  ///   - value: The value of the short global ID.
  ///   - shouldFetchRootRecord: Whether to fetch the root record alongside
  ///     the share.
  ///   - rootRecordDesiredKeys: Field names limiting the root record payload.
  public init(
    value: ShortGUID,
    shouldFetchRootRecord: Bool? = nil,
    rootRecordDesiredKeys: [String]? = nil
  ) {
    self.value = value
    self.shouldFetchRootRecord = shouldFetchRootRecord
    self.rootRecordDesiredKeys = rootRecordDesiredKeys
  }

  internal init(from schema: Components.Schemas.ShortGUID) {
    self.value = schema.value
    self.shouldFetchRootRecord = schema.shouldFetchRootRecord
    self.rootRecordDesiredKeys = schema.rootRecordDesiredKeys
  }
}

// MARK: - Internal Conversion
extension Components.Schemas.ShortGUID {
  internal init(from dictionary: ShortGUIDDictionary) {
    self.init(
      value: dictionary.value,
      shouldFetchRootRecord: dictionary.shouldFetchRootRecord,
      rootRecordDesiredKeys: dictionary.rootRecordDesiredKeys
    )
  }
}

//
//  Reference+NormalizedZone.swift
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

extension Reference {
  /// The reference with its zone read by name and owner only (no
  /// ``ZoneID/zoneType``), and the default zone as no zone.
  ///
  /// CloudKit sends every reference's `zoneID` with `ownerRecordName` and
  /// `zoneType`; this gives one form for the same target whichever way the
  /// reference was read or built.
  public var normalizedZone: Reference {
    let zone = zoneID.flatMap { zoneID in zoneID.isDefaultZone ? nil : zoneID.identity }
    return Reference(recordName: recordName, zoneID: zone, action: action)
  }
}

extension FieldValue {
  /// The value with each reference's zone normalized
  /// (``Reference/normalizedZone``); other values are returned unchanged.
  public var withNormalizedReferences: FieldValue {
    switch self {
    case .reference(.value(let reference)):
      .reference(.value(reference.normalizedZone))
    case .reference(.list(let references)):
      .reference(.list(references.map(\.normalizedZone)))
    default:
      self
    }
  }
}

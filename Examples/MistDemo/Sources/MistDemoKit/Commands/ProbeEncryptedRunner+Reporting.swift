//
//  ProbeEncryptedRunner+Reporting.swift
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

internal import Foundation
internal import MistKit

extension ProbeEncryptedRunner {
  internal static func describe(_ error: any Error) -> String {
    guard let cloudKitError = error as? CloudKitError else {
      return String(describing: error)
    }
    let status = cloudKitError.httpStatusCode.map(String.init) ?? "n/a"
    let code = cloudKitError.serverErrorCode ?? "<none>"
    return "status=\(status) serverErrorCode=\(code) — \(cloudKitError.localizedDescription)"
  }

  private static func describeSecret(_ value: FieldValue?) -> String {
    switch value {
    case .string(.value(let text)) where text == secretValue:
      return "secret=plaintext (matches)"
    case .string(.value(let text)):
      return "secret=\"\(text)\" (differs)"
    case .some(let other):
      return "secret=\(other) (unexpected type)"
    case nil:
      return "secret=absent"
    }
  }

  /// One line per record result; per-record failures surface the wire
  /// `serverErrorCode` and `reason` verbatim.
  internal mutating func report(_ results: [RecordResult], step name: String) {
    for result in results {
      switch result {
      case .success(let record):
        remember(record)
        pass(name, inspect(record))
      case .failure(let failure):
        let reason = failure.reason ?? "<no reason>"
        fail(name, "\(failure.identifier): \(failure.serverErrorCode.rawValue) — \(reason)")
      }
    }
  }

  /// For list-shaped reads (query, changes): reports which probe records the
  /// response contained and flags the missing ones.
  internal mutating func reportFound(in records: [RecordInfo], step name: String) {
    for recordName in probeRecordNames {
      if let record = records.first(where: { $0.recordName == recordName }) {
        remember(record)
        pass(name, inspect(record))
      } else {
        fail(name, "\(recordName): not in response (\(records.count) record(s) returned)")
      }
    }
  }

  private mutating func remember(_ record: RecordInfo) {
    if record.recordName == config.recordName, !record.deleted {
      encryptedRecord = record
    }
  }

  /// Describes the secret field, whether `isEncrypted` was echoed, and
  /// whether the asset came back — the three facts issue #392 asks for.
  internal func inspect(_ record: RecordInfo) -> String {
    var parts = [record.recordName]
    if record.deleted {
      parts.append("tombstone")
    }
    parts.append(Self.describeSecret(record.fields[Self.secretField]))
    if record.encryptedFields.isEmpty {
      parts.append("isEncrypted not echoed")
    } else {
      parts.append("isEncrypted echoed for \(record.encryptedFields.sorted())")
    }
    if case .asset? = record.fields[Self.assetField] {
      parts.append("asset present")
    }
    return parts.joined(separator: " · ")
  }
}

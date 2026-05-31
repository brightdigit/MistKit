//
//  MockBackend+Helpers.swift
//  MistDemoTests
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

#if canImport(Hummingbird)
  internal import Foundation
  internal import MistKit

  extension MockBackend {
    internal static func stubRecord(
      recordType: String, recordName: String
    ) -> RecordInfo {
      let json = """
        {
          "recordName": "\(recordName)",
          "recordType": "\(recordType)",
          "recordChangeTag": null,
          "fields": {},
          "created": null,
          "modified": null,
          "deleted": false
        }
        """
      // RecordInfo is Codable; round-trip through JSON keeps the stub
      // independent of MistKit's internal initializer.
      do {
        return try JSONDecoder().decode(
          RecordInfo.self, from: Data(json.utf8)
        )
      } catch {
        fatalError("MockBackend stubRecord JSON failed to decode: \(error)")
      }
    }

    /// Flatten FieldValue entries into a printable form so tests can write
    /// `#expect(captured.fields["title"] == "Hi")` for strings or
    /// `#expect(captured.fields["index"] == "5")` for numbers without
    /// pattern-matching on FieldValue in every assertion.
    ///
    /// Non-primitive cases (asset, date, reference, location, list, bytes)
    /// are intentionally dropped — they yield no useful String form for an
    /// equality assertion. Tests that need to assert those types should
    /// inspect the FieldValue directly rather than going through `flatten`.
    internal static func flatten(
      _ fields: [String: FieldValue]
    ) -> [String: String] {
      var result: [String: String] = [:]
      for (name, value) in fields {
        switch value {
        case .string(let string):
          result[name] = string
        case .int64(let int):
          result[name] = String(int)
        case .double(let double):
          result[name] = String(double)
        default:
          continue
        }
      }
      return result
    }
  }
#endif

//
//  MistDemoConfiguration+Testing.swift
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

import Configuration
import Foundation

@testable import MistDemoKit

extension MistDemoConfiguration {
  /// Build a `MistDemoConfiguration` backed by a single `InMemoryProvider`.
  ///
  /// String keys are split on `.` to form the underlying `AbsoluteConfigKey`
  /// components, so callers can write `"container.identifier"` /
  /// `"record.type"` exactly as production code reads them via
  /// `MistDemoConfiguration.string(forKey:)`. Single-segment keys
  /// (`"file"`, `"record-type"`) work too — the split just yields a one-element
  /// path.
  internal static func testing(
    _ values: [String: ConfigValue]
  ) -> MistDemoConfiguration {
    func key(_ path: String) -> AbsoluteConfigKey {
      AbsoluteConfigKey(
        path.split(separator: ".").map(String.init),
        context: [:]
      )
    }

    var mapped: [AbsoluteConfigKey: ConfigValue] = [:]
    for (rawKey, value) in values {
      mapped[key(rawKey)] = value
    }
    return MistDemoConfiguration(
      testProvider: InMemoryProvider(values: mapped)
    )
  }
}

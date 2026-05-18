//
//  DemoErrorsRunner+Output.swift
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

extension DemoErrorsRunner {
  internal func printRunnerHeader() {
    print("\n" + String(repeating: "=", count: 80))
    print("🛑 CloudKit Error Demo — typed CloudKitError handling")
    print(String(repeating: "=", count: 80))
    print("Container: \(config.containerIdentifier)")
    print("Database:  \(config.database.pathSegment)")
    print(String(repeating: "=", count: 80))
  }

  internal func printRunnerFooter() {
    print("\n" + String(repeating: "=", count: 80))
    print("✅ Error demo complete")
    print(String(repeating: "=", count: 80))
  }

  internal func printSectionHeader(_ title: String) {
    print("\n" + String(repeating: "-", count: 80))
    print("▶ \(title)")
    print(String(repeating: "-", count: 80))
  }

  internal func printCloudKitError(_ error: CloudKitError, expectedStatus: Int) {
    let status = error.httpStatusCode.map(String.init) ?? "n/a"
    let prefix = error.httpStatusCode == expectedStatus ? "✅" : "❌"
    print("\(prefix) Caught CloudKitError — status: \(status)")
    if case .httpErrorWithDetails(_, let serverErrorCode, let reason) = error {
      print("   serverErrorCode: \(serverErrorCode ?? "<none>")")
      print("   reason:          \(reason ?? "<none>")")
    } else {
      print("   detail: \(error.localizedDescription)")
    }
  }

  internal func describe(_ tag: String?) -> String {
    guard let tag, !tag.isEmpty else {
      return "<none>"
    }
    return tag
  }
}

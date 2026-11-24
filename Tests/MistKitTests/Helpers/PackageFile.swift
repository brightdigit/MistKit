//
//  PackageFile.swift
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

/// Locates files committed to the package, such as `Examples/*/schema.ckdb`,
/// on every platform the tests run on.
///
/// Mirrors SyndiKit's `Content.Directories`: the working directory comes first,
/// because that's where the sandboxed runners put the files.
/// - WASI: swift-build runs the test binary with `--dir .`, so the package root
///   is the working directory and `#filePath` (a host path) isn't visible.
/// - Android: CI stages `Examples/*/schema.ckdb` and copies it (`android-copy-files`)
///   next to the test binary, which runs from that folder on the emulator.
/// - macOS, Linux, Windows: `#filePath` locates the checkout.
internal enum PackageFile {
  /// The package root derived from this file's location in the checkout.
  private static let sourceRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()  // Helpers
    .deletingLastPathComponent()  // MistKitTests
    .deletingLastPathComponent()  // Tests
    .deletingLastPathComponent()

  /// The URL of `relativePath` (from the package root), found by trying the
  /// working directory, its parents, then the source checkout. When none has
  /// it, returns the working-directory candidate, so the read fails with that
  /// path in the error.
  internal static func url(_ relativePath: String) -> URL {
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: relativePath) {
      return URL(fileURLWithPath: relativePath)
    }
    let workingDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    var roots = [workingDirectory]
    var parent = workingDirectory
    for _ in 0..<3 {
      parent = parent.deletingLastPathComponent()
      roots.append(parent)
    }
    roots.append(sourceRoot)
    for root in roots {
      let candidate = root.appendingPathComponent(relativePath)
      if fileManager.fileExists(atPath: candidate.path) {
        return candidate
      }
    }
    return workingDirectory.appendingPathComponent(relativePath)
  }
}

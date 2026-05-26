//
//  IntegrationTestData.swift
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

/// Test data generation utilities for integration tests.
internal enum IntegrationTestData {
  /// CloudKit record type for integration tests.
  internal static let recordType = "Note"

  /// Solid fill color (RGB) for the generated test image.
  private static let fillRed: UInt8 = 0x34
  private static let fillGreen: UInt8 = 0x9F
  private static let fillBlue: UInt8 = 0xE6

  /// Generate a real, decodable solid-color PNG for upload testing.
  ///
  /// Delegates the byte-level encoding to ``PNGEncoder``, which produces a
  /// cross-platform (Linux/WASI), Dashboard-renderable PNG with no
  /// CoreGraphics/ImageIO dependency.
  ///
  /// `sizeKB` is a size hint: the image is a square whose pixel dimensions are
  /// scaled so the encoded PNG approximates the requested size.
  ///
  /// - Parameter sizeKB: Desired approximate size in kilobytes (default: 10)
  /// - Returns: Valid PNG image data
  internal static func generateTestImage(sizeKB: Int = 10) -> Data {
    let targetBytes = max(1, sizeKB) * 1_024
    // Raw image bytes ≈ height * (1 + width * 3) ≈ 3 * side² for a square.
    let side = max(1, Int((Double(targetBytes) / 3.0).squareRoot().rounded()))
    return PNGEncoder.encode(
      width: side, height: side, red: fillRed, green: fillGreen, blue: fillBlue
    )
  }
}

//
//  PNGData.swift
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

/// Minimal, dependency-free PNG encoder for solid-color images.
///
/// Built entirely from `Data` — correct per-chunk CRC-32 and a valid zlib
/// stream using uncompressed ("stored") DEFLATE blocks plus an Adler-32
/// checksum — so the output renders in the CloudKit Dashboard and any standard
/// PNG decoder. No CoreGraphics/ImageIO dependency, so it stays cross-platform
/// (Linux/WASI).
internal enum PNGData {
  /// Solid fill color (RGB) for the generated test image.
  private static let fillRed: UInt8 = 0x34
  private static let fillGreen: UInt8 = 0x9F
  private static let fillBlue: UInt8 = 0xE6

  /// Encode a solid-color RGB image as a valid PNG.
  ///
  /// - Parameters:
  ///   - width: Image width in pixels.
  ///   - height: Image height in pixels.
  ///   - red: Red channel for every pixel.
  ///   - green: Green channel for every pixel.
  ///   - blue: Blue channel for every pixel.
  /// - Returns: Valid PNG image data.
  private static func encode(
    width: Int,
    height: Int,
    red: UInt8,
    green: UInt8,
    blue: UInt8
  ) -> Data {
    // Raw image data: each scanline is a filter-type byte (0 = None) followed
    // by `width` RGB pixels.
    var raw = [UInt8]()
    raw.reserveCapacity(height * (1 + width * 3))
    for _ in 0..<height {
      raw.append(0x00)
      for _ in 0..<width {
        raw.append(red)
        raw.append(green)
        raw.append(blue)
      }
    }

    var png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])  // signature

    // IHDR: width, height, bit depth 8, color type 2 (RGB), no compression/
    // filter/interlace metadata flags.
    var ihdr = [UInt8]()
    ihdr.append(contentsOf: bigEndianBytes(UInt32(width)))
    ihdr.append(contentsOf: bigEndianBytes(UInt32(height)))
    ihdr.append(contentsOf: [0x08, 0x02, 0x00, 0x00, 0x00])
    png.append(chunk(type: "IHDR", payload: ihdr))

    png.append(chunk(type: "IDAT", payload: zlibStored(raw)))
    png.append(chunk(type: "IEND", payload: []))

    return png
  }

  /// Build one PNG chunk: length, type, payload, and CRC-32 over type+payload.
  private static func chunk(type: String, payload: [UInt8]) -> Data {
    let typeBytes = Array(type.utf8)
    var data = Data()
    data.append(contentsOf: bigEndianBytes(UInt32(payload.count)))
    data.append(contentsOf: typeBytes)
    data.append(contentsOf: payload)
    data.append(contentsOf: bigEndianBytes(crc32(typeBytes + payload)))
    return data
  }

  /// Wrap raw bytes in a zlib stream using uncompressed DEFLATE blocks.
  private static func zlibStored(_ raw: [UInt8]) -> [UInt8] {
    var out: [UInt8] = [0x78, 0x01]  // zlib header (CM=deflate, no preset dict)

    let maxBlock = 0xFFFF
    var offset = 0
    if raw.isEmpty {
      // A single empty, final stored block.
      out.append(contentsOf: [0x01, 0x00, 0x00, 0xFF, 0xFF])
    } else {
      while offset < raw.count {
        let len = min(maxBlock, raw.count - offset)
        let isFinal = offset + len >= raw.count
        out.append(isFinal ? 0x01 : 0x00)  // BFINAL + BTYPE=00 (stored)
        let len16 = UInt16(len)
        out.append(UInt8(len16 & 0xFF))  // LEN, little-endian
        out.append(UInt8(len16 >> 8))
        out.append(UInt8(~len16 & 0xFF))  // NLEN = ~LEN
        out.append(UInt8(~len16 >> 8))
        out.append(contentsOf: raw[offset..<(offset + len)])
        offset += len
      }
    }

    out.append(contentsOf: bigEndianBytes(adler32(raw)))  // zlib trailer
    return out
  }

  /// Big-endian 4-byte representation of a `UInt32`.
  private static func bigEndianBytes(_ value: UInt32) -> [UInt8] {
    [
      UInt8((value >> 24) & 0xFF),
      UInt8((value >> 16) & 0xFF),
      UInt8((value >> 8) & 0xFF),
      UInt8(value & 0xFF),
    ]
  }

  /// PNG CRC-32 (polynomial 0xEDB88320) over the given bytes.
  private static func crc32(_ bytes: [UInt8]) -> UInt32 {
    var crc: UInt32 = 0xFFFF_FFFF
    for byte in bytes {
      crc ^= UInt32(byte)
      for _ in 0..<8 {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB8_8320 : (crc >> 1)
      }
    }
    return crc ^ 0xFFFF_FFFF
  }

  /// Adler-32 checksum (the zlib stream trailer) over the given bytes.
  private static func adler32(_ bytes: [UInt8]) -> UInt32 {
    let modulus: UInt32 = 65_521
    var lowSum: UInt32 = 1
    var highSum: UInt32 = 0
    for byte in bytes {
      lowSum = (lowSum + UInt32(byte)) % modulus
      highSum = (highSum + lowSum) % modulus
    }
    return (highSum << 16) | lowSum
  }

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
  internal static func generate(withSizeInKB sizeKB: Int = 10) -> Data {
    let targetBytes = max(1, sizeKB) * 1_024
    // Raw image bytes ≈ height * (1 + width * 3) ≈ 3 * side² for a square.
    let side = max(1, Int((Double(targetBytes) / 3.0).squareRoot().rounded()))
    return encode(
      width: side, height: side, red: fillRed, green: fillGreen, blue: fillBlue
    )
  }
}

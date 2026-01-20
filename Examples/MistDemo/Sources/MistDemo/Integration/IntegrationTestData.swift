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

import Foundation

/// Test data generation utilities for integration tests
struct IntegrationTestData {
    /// CloudKit record type for integration tests
    static let recordType = "MistKitIntegrationTest"

    /// Generate minimal valid PNG image data
    /// - Parameter sizeKB: Desired size in kilobytes (default: 10)
    /// - Returns: PNG image data
    static func generateTestImage(sizeKB: Int = 10) -> Data {
        // Minimal valid 1x1 pixel PNG
        // PNG signature
        var data = Data([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A
        ])

        // IHDR chunk (image header) for 1x1 pixel RGBA image
        let ihdrData: [UInt8] = [
            0x00, 0x00, 0x00, 0x0D,  // Chunk length: 13 bytes
            0x49, 0x48, 0x44, 0x52,  // Chunk type: "IHDR"
            0x00, 0x00, 0x00, 0x01,  // Width: 1
            0x00, 0x00, 0x00, 0x01,  // Height: 1
            0x08,                     // Bit depth: 8
            0x06,                     // Color type: RGBA
            0x00,                     // Compression: deflate
            0x00,                     // Filter: adaptive
            0x00,                     // Interlace: none
            0x1F, 0x15, 0xC4, 0x89   // CRC32 checksum
        ]
        data.append(contentsOf: ihdrData)

        // IDAT chunk (image data) - minimal compressed pixel data
        let idatData: [UInt8] = [
            0x00, 0x00, 0x00, 0x0C,  // Chunk length: 12 bytes
            0x49, 0x44, 0x41, 0x54,  // Chunk type: "IDAT"
            0x08, 0x1D, 0x01, 0x02, 0x00, 0xFD, 0xFF,  // Compressed data
            0x00, 0x00, 0x00, 0x02, 0x00, 0x01,
            0xE2, 0x21, 0xBC, 0x33   // CRC32 checksum
        ]
        data.append(contentsOf: idatData)

        // IEND chunk (image trailer)
        let iendData: [UInt8] = [
            0x00, 0x00, 0x00, 0x00,  // Chunk length: 0
            0x49, 0x45, 0x4E, 0x44,  // Chunk type: "IEND"
            0xAE, 0x42, 0x60, 0x82   // CRC32 checksum
        ]
        data.append(contentsOf: iendData)

        // Pad to requested size with additional IDAT chunks if needed
        let targetSize = sizeKB * 1024
        while data.count < targetSize {
            // Add padding IDAT chunks
            let remainingBytes = targetSize - data.count
            let chunkSize = min(8192, remainingBytes - 12)  // Leave room for chunk overhead

            if chunkSize <= 0 {
                break
            }

            // Chunk length (4 bytes)
            var lengthBytes: [UInt8] = [
                UInt8((chunkSize >> 24) & 0xFF),
                UInt8((chunkSize >> 16) & 0xFF),
                UInt8((chunkSize >> 8) & 0xFF),
                UInt8(chunkSize & 0xFF)
            ]
            data.append(contentsOf: lengthBytes)

            // Chunk type: "IDAT"
            data.append(contentsOf: [0x49, 0x44, 0x41, 0x54])

            // Padding data
            data.append(contentsOf: Array(repeating: UInt8(0x00), count: chunkSize))

            // Simple CRC32 (not accurate, but sufficient for test data)
            data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
        }

        return data
    }
}

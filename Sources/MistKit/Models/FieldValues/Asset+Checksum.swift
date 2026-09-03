//
//  Asset+Checksum.swift
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

internal import Crypto
public import Foundation

extension Asset {
  private static let hexDigits: [Character] = Array("0123456789abcdef")

  /// Returns whether `data` is the plaintext file this asset describes.
  ///
  /// Hashes the raw plaintext bytes with SHA-256 and compares the digest to
  /// ``fileChecksum``. The checksum is first interpreted as the base64 encoding
  /// of the digest (the same convention as CloudKit request body hashes). If
  /// that comparison fails, the checksum is compared to the hex encoding of
  /// the digest, case-insensitively.
  ///
  /// Returns `false` when ``fileChecksum`` is missing. CDN `wrappingKey`
  /// encryption is out of scope: this method never unwraps or decrypts.
  ///
  /// - Parameter data: Plaintext file bytes. Encrypted CDN payloads are not
  ///   decoded here.
  /// - Returns: Whether `data`'s SHA-256 digest matches ``fileChecksum``.
  public func matches(data: Data) -> Bool {
    guard let fileChecksum else {
      return false
    }
    let digest = Data(SHA256.hash(data: data))
    if fileChecksum == digest.base64EncodedString() {
      return true
    }
    return fileChecksum.lowercased() == Self.hexEncoded(digest)
  }

  private static func hexEncoded(_ data: Data) -> String {
    data.reduce(into: "") { result, byte in
      result.append(Self.hexDigits[Int(byte >> 4)])
      result.append(Self.hexDigits[Int(byte & 0x0F)])
    }
  }
}

//
//  Asset.swift
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

/// Asset dictionary as defined in CloudKit Web Services
public struct Asset: Codable, Equatable, Sendable {
  /// Opaque, server-minted checksum identifying the stored file.
  ///
  /// Apple documents this only as a signature and specifies no algorithm. It is
  /// produced by the CDN upload receipt, not computed by the client, and is not
  /// a digest of the plaintext bytes — observed values are a `0x01` version
  /// byte plus a 20-byte digest, and it doubles as the content address in
  /// ``downloadURL``. Treat it as an identity/caching token; it cannot be
  /// recomputed to validate downloaded bytes. Use ``size`` for that.
  public let fileChecksum: String?
  /// The file size in bytes
  public let size: Int64?
  /// The reference checksum
  public let referenceChecksum: String?
  /// The wrapping key for encryption
  public let wrappingKey: String?
  /// The upload receipt
  public let receipt: String?
  /// The download URL
  public let downloadURL: String?

  /// Initialize an asset value
  public init(
    fileChecksum: String? = nil,
    size: Int64? = nil,
    referenceChecksum: String? = nil,
    wrappingKey: String? = nil,
    receipt: String? = nil,
    downloadURL: String? = nil
  ) {
    self.fileChecksum = fileChecksum
    self.size = size
    self.referenceChecksum = referenceChecksum
    self.wrappingKey = wrappingKey
    self.receipt = receipt
    self.downloadURL = downloadURL
  }
}

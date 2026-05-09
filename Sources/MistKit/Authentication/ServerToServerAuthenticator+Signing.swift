//
//  ServerToServerAuthenticator+Signing.swift
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

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension ServerToServerAuthenticator {
  /// Signs a CloudKit Web Services request.
  ///
  /// - Parameters:
  ///   - requestBody: The HTTP request body (for POST requests). May be nil.
  ///   - webServiceURL: The CloudKit Web Services URL subpath.
  ///   - date: The request date. Defaults to `Date()`.
  /// - Returns: A `RequestSignature` containing the headers required by
  ///   CloudKit.
  /// - Throws: A `Crypto` error if `P256.Signing.PrivateKey.signature(for:)`
  ///   fails to produce a signature.
  public func signRequest(
    requestBody: Data?,
    webServiceURL: String,
    date: Date = Date()
  ) throws -> RequestSignature {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
    let iso8601Date = formatter.string(from: date)

    let bodyHash: String
    if let requestBody {
      let hash = SHA256.hash(data: requestBody)
      bodyHash = Data(hash).base64EncodedString()
    } else {
      bodyHash = ""
    }

    let payload = "\(iso8601Date):\(bodyHash):\(webServiceURL)"
    let signature = try privateKey.signature(for: Data(payload.utf8))
    return RequestSignature(
      keyID: keyID,
      date: iso8601Date,
      signature: signature.derRepresentation.base64EncodedString()
    )
  }
}

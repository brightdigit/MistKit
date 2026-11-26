//
//  ConfigurationLoaderTests+Fixtures.swift
//  BushelCloud
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

@testable import BushelCloudKit

extension ConfigurationLoaderTests {
  /// A syntactically valid Server-to-Server key ID: exactly 64 hex characters.
  ///
  /// ``KeyIDValidator`` checks shape, so fixtures must be well-formed even
  /// though no CloudKit request is made.
  internal static let validKeyID =
    "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2"

  /// A structurally valid PEM: correct header/footer and base64-decodable body.
  ///
  /// Not a usable key — ``PEMValidator`` checks structure, not cryptographic
  /// content.
  internal static let validPEM = """
    -----BEGIN PRIVATE KEY-----
    bm90IGEgcmVhbCBrZXksIGJ1dCB2YWxpZCBiYXNlNjQgc28gUEVNVmFsaWRhdG9yIGFjY2VwdHMgaXQ=
    -----END PRIVATE KEY-----
    """
}

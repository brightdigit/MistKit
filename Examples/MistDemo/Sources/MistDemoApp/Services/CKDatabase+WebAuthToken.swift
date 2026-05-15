//
//  CKDatabase+WebAuthToken.swift
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

#if canImport(CloudKit) && !os(tvOS) && !os(watchOS)
  import CloudKit

  extension CKDatabase {
    /// Capture a web-auth token via `CKFetchWebAuthTokenOperation` for the
    /// given CloudKit API token. Issues the same `158__…` value that
    /// MistKit / `mistdemo auth-token` consume.
    ///
    /// `CKFetchWebAuthTokenOperation` must run against the private database
    /// — running it on the public database fails or returns an unattributed
    /// token.
    internal func fetchWebAuthToken(apiToken: String) async throws -> String {
      try await withCheckedThrowingContinuation { continuation in
        let operation = CKFetchWebAuthTokenOperation(apiToken: apiToken)
        operation.qualityOfService = .userInitiated
        operation.fetchWebAuthTokenResultBlock = { @Sendable result in
          continuation.resume(with: result)
        }
        add(operation)
      }
    }
  }
#endif

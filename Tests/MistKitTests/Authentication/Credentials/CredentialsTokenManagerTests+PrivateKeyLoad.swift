//
//  CredentialsTokenManagerTests+PrivateKeyLoad.swift
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
internal import Testing

@testable import MistKit

extension CredentialsTokenManagerTests {
  @Suite("Private-Key Load Failure")
  internal struct PrivateKeyLoad {
    @Test(".public + S2S with unreadable PEM file → throws invalidPrivateKey")
    internal func publicWithUnreadablePEMFileThrowsInvalidPrivateKey() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        return
      }
      let missingPath = "/nonexistent/path/to/private-key-\(UUID().uuidString).pem"
      let credentials = try Credentials(
        serverToServer: ServerToServerCredentials(
          keyID: "test-key-id-12345678",
          privateKey: .file(path: missingPath)
        )
      )
      do {
        _ = try credentials.makeTokenManager(for: .public(.requires(.serverToServer)))
        Issue.record("expected makeTokenManager to throw .invalidPrivateKey")
      } catch let error as CloudKitError {
        guard case .invalidPrivateKey(let path, _) = error else {
          Issue.record("expected .invalidPrivateKey, got \(error)")
          return
        }
        #expect(path == missingPath)
      }
    }
  }
}

//
//  AuthTokenIndexHTML.swift
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

#if canImport(Hummingbird)
  internal import Foundation

  /// Loader for the CloudKit auth-flow page served by `AuthTokenServer`.
  ///
  /// The HTML+JS lives in `Resources/auth-token-index.html` and is read
  /// from `Bundle.module` on first access. The resource only ships in the
  /// MistDemoKit bundle, which is consumed exclusively by the `mistdemo`
  /// CLI executable (macOS / Linux); the iOS MistDemoApp target does not
  /// depend on MistDemoKit and therefore never bundles this resource.
  internal enum AuthTokenIndexHTML {
    internal static let content: String = {
      guard
        let url = Bundle.module.url(
          forResource: "auth-token-index",
          withExtension: "html"
        ),
        let data = try? Data(contentsOf: url),
        let string = String(data: data, encoding: .utf8)
      else {
        preconditionFailure(
          "auth-token-index.html missing from MistDemoKit bundle"
        )
      }
      return string
    }()
  }
#endif

//
//  WebAuthTokenStoreTests.swift
//  MistDemoTests
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
  internal import Testing

  @testable import MistDemoKit

  @Suite("WebAuthTokenStore Tests")
  internal struct WebAuthTokenStoreTests {
    @Test("Starts empty when initialized without a token")
    internal func startsEmpty() async {
      let store = WebAuthTokenStore()
      let value = await store.currentToken
      #expect(value == nil)
    }

    @Test("Returns the token passed to the initializer")
    internal func preSeeded() async {
      let store = WebAuthTokenStore(token: "seed")
      let value = await store.currentToken
      #expect(value == "seed")
    }

    @Test("update(_:) replaces the stored token")
    internal func updateReplaces() async {
      let store = WebAuthTokenStore()
      await store.update("first")
      await store.update("second")
      let value = await store.currentToken
      #expect(value == "second")
    }

    @Test("clear() removes the stored token")
    internal func clearRemoves() async {
      let store = WebAuthTokenStore(token: "tok")
      await store.clear()
      let value = await store.currentToken
      #expect(value == nil)
    }
  }
#endif

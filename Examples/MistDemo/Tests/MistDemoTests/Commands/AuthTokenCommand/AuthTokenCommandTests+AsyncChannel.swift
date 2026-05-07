//
//  AuthTokenCommandTests+AsyncChannel.swift
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
  import AsyncAlgorithms
  import Foundation
  import Testing

  @testable import MistDemoKit

  extension AuthTokenCommandTests {
    @Suite("AsyncChannel")
    internal struct AsyncChannelTests {
      @Test("AsyncChannel sends and receives values")
      internal func asyncChannelSendsAndReceives() async {
        let channel = AsyncChannel<String>()

        Task {
          await channel.send("test-value")
        }

        var iterator = channel.makeAsyncIterator()
        let value = await iterator.next()
        #expect(value == "test-value")
      }

      @Test("AsyncChannel handles multiple values sequentially")
      internal func asyncChannelHandlesMultipleValues() async {
        let channel = AsyncChannel<Int>()
        var iterator = channel.makeAsyncIterator()

        Task { await channel.send(1) }
        #expect(await iterator.next() == 1)

        Task { await channel.send(2) }
        #expect(await iterator.next() == 2)

        Task { await channel.send(3) }
        #expect(await iterator.next() == 3)
      }
    }
  }
#endif

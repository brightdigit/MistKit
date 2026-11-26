//
//  ReplayingBodyIterator.swift
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
internal import OpenAPIRuntime

#if !os(WASI)
  /// Yields a buffered prefix, then continues the partially consumed source
  /// iterator, so a body inspected by ``LoggingMiddleware`` can still be
  /// read once by the caller. If the source failed mid-read the error is
  /// rethrown after the prefix, matching what the caller would have seen
  /// without logging.
  ///
  /// An actor rather than a class: `HTTPBody.Iterator` is not `Sendable`,
  /// and the stream's producer closure has to be.
  internal actor ReplayingBodyIterator {
    private var prefix: Data?
    private let error: (any Error)?
    /// `HTTPBody.Iterator.next()` is `mutating async`, which cannot be called
    /// on actor-isolated storage; the iterator is captured in a closure that
    /// lives with the actor instead.
    private let produceNext: () async throws -> HTTPBody.ByteChunk?

    internal init(prefix: Data, remainder: HTTPBody.Iterator, error: (any Error)? = nil) {
      self.prefix = prefix
      self.error = error
      var iterator = remainder
      self.produceNext = { try await iterator.next() }
    }

    nonisolated internal func stream() -> AsyncThrowingStream<HTTPBody.ByteChunk, any Error> {
      AsyncThrowingStream { try await self.next() }
    }

    private func next() async throws -> HTTPBody.ByteChunk? {
      if let prefix {
        self.prefix = nil
        return ArraySlice(prefix)
      }
      if let error {
        throw error
      }
      return try await produceNext()
    }
  }
#endif

//
//  CapturedLogs.swift
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

internal import Logging

/// The messages a test logger received, for asserting on what was logged.
internal struct CapturedLogs: Sendable {
  /// One logged message.
  internal struct Entry: Sendable {
    internal let level: Logger.Level
    internal let message: String
  }

  private let stream: AsyncStream<Entry>
  private let continuation: AsyncStream<Entry>.Continuation

  internal init() {
    (stream, continuation) = AsyncStream.makeStream(of: Entry.self)
  }

  /// A logger at `level` that records into this store.
  internal func logger(level: Logger.Level = .trace) -> Logger {
    var logger = Logger(label: "com.brightdigit.MistKit.test") { _ in
      CapturingLogHandler(continuation: continuation)
    }
    logger.logLevel = level
    return logger
  }

  /// Every message logged so far, in order. Ends the capture: call it once,
  /// after the code under test has finished logging.
  internal func entries() async -> [Entry] {
    continuation.finish()
    var entries: [Entry] = []
    for await entry in stream {
      entries.append(entry)
    }
    return entries
  }
}

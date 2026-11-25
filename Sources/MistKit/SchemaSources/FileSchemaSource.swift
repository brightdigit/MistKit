//
//  FileSchemaSource.swift
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

public import Foundation

/// A schema read from a CloudKit Schema Language (`.ckdb`) file.
///
/// MistKit doesn't watch files, so the caller passes a stream that yields when
/// the file may have changed (for example from a `DispatchSource` on it).
/// ``schemaChanges()`` passes a notification on only when the file's bytes
/// differ from what was last read, so a save that rewrites the same bytes
/// doesn't ask for a reload. A file that can no longer be read counts as
/// changed, so the reload reports the error.
public actor FileSchemaSource: SchemaSource {
  /// The file.
  nonisolated public let url: URL

  private let fileChanges: @Sendable () -> AsyncStream<Void>
  private var lastContents: Data?

  /// Creates a source for a file.
  ///
  /// - Parameters:
  ///   - url: The file's URL.
  ///   - fileChanges: Makes a stream that yields whenever the file may have
  ///     changed. The default never yields.
  public init(
    url: URL,
    fileChanges: @escaping @Sendable () -> AsyncStream<Void> = { AsyncStream { $0.finish() } }
  ) {
    self.url = url
    self.fileChanges = fileChanges
  }

  /// Reads and parses the file.
  ///
  /// - Throws: What ``CloudKitSchema/init(contentsOf:)`` throws.
  public func loadSchema() async throws -> CloudKitSchema {
    let data: Data
    do {
      data = try Data(contentsOf: url)
    } catch {
      lastContents = nil
      throw SchemaSourceError.unreadableFile(url, underlying: error)
    }
    lastContents = data
    return try CloudKitSchema(data: data, from: url)
  }

  /// Yields when a file-change notification finds the file's bytes changed;
  /// finishes when the notifications do.
  nonisolated public func schemaChanges() -> AsyncStream<Void> {
    let notifications = fileChanges()
    return AsyncStream { continuation in
      let task = Task {
        for await _ in notifications where await self.contentsChanged() {
          continuation.yield()
        }
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  /// Whether the file now differs from what was last seen, remembering it.
  private func contentsChanged() -> Bool {
    guard let data = try? Data(contentsOf: url) else {
      lastContents = nil
      return true
    }
    guard data != lastContents else {
      return false
    }
    lastContents = data
    return true
  }
}

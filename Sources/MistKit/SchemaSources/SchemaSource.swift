//
//  SchemaSource.swift
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

/// Produces a container environment's schema, and says when to load it again.
///
/// MistKit has three: ``ExportedSchemaSource`` (the Management API export),
/// ``FileSchemaSource`` (a `.ckdb` file) and ``InferredSchemaSource`` (query
/// results). They throw MistKit's errors; an app maps them, and stamps a
/// loaded schema with where and when it came from if it needs to.
public protocol SchemaSource: Sendable {
  /// Loads the schema.
  func loadSchema() async throws -> CloudKitSchema

  /// A stream that yields whenever the schema should be loaded again, such as
  /// when a `.ckdb` file changed.
  ///
  /// It finishes when the source will never ask again. The default finishes
  /// at once.
  func schemaChanges() -> AsyncStream<Void>
}

extension SchemaSource {
  /// A stream that finishes at once: the source never asks for a reload.
  public func schemaChanges() -> AsyncStream<Void> {
    AsyncStream { $0.finish() }
  }
}

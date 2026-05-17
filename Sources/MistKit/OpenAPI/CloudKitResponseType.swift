//
//  CloudKitResponseType.swift
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

/// Protocol for CloudKit operation response types that support unified error handling.
/// Conformers exhaustively switch over their response cases so a new case in
/// `openapi.yaml` becomes a build error instead of being silently dropped.
///
/// - TODO: The per-operation `Operations.*.Output` conformances in
///   `OpenAPI/Operations/Operations.*.Output.swift` are mechanical, identical
///   except for the type name, and replicate the same status-code-to-case
///   mapping. Replace them with an internal attached macro
///   (e.g. `@CloudKitResponse`) that synthesizes `toCloudKitError()` from
///   the response enum's cases, eliminating ~13 boilerplate files.
internal protocol CloudKitResponseType {
  /// Returns the `CloudKitError` for this response, or `nil` for `.ok`.
  func toCloudKitError() -> CloudKitError?
}

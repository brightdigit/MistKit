//
//  FieldTypeTagging.swift
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

/// When a CloudKit Web Services field dictionary carries its `type`.
///
/// CloudKit infers most request types from the value's JSON shape, so MistKit
/// tags only the ambiguous scalars (`TIMESTAMP`, `BYTES`, `DOUBLE`) and every
/// list (`*_LIST`). Responses tag every value. Pick ``always`` to write JSON that
/// reads like a response, for display or export.
public enum FieldTypeTagging: Sendable, Hashable {
  /// Tag only where CloudKit can't infer the type: what MistKit sends.
  case whenRequired
  /// Tag every value, as CloudKit's responses do.
  case always
}

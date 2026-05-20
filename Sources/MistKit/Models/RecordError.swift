//
//  RecordError.swift
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

public import MistKitOpenAPI

/// A per-record error returned inline in a CloudKit `modifyRecords` or
/// `lookupRecords` response.
///
/// CloudKit reports per-operation failures as error entries within the
/// otherwise-successful (HTTP 200) `records` array, carrying the failed
/// record's name, a server error code, and optional retry/redirect hints.
/// `RecordError` reuses the generated OpenAPI schema type directly so no
/// information is discarded.
///
/// Surfaced via ``RecordResult/failure(_:)`` from `modifyRecords` /
/// `lookupRecords`, and wrapped in ``CloudKitError/recordOperationFailed(_:)``
/// when a single-record convenience (`createRecord`/`updateRecord`/
/// `deleteRecord`) hits one.
public typealias RecordError = Components.Schemas.RecordError

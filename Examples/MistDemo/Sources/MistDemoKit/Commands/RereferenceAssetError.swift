//
//  RereferenceAssetError.swift
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

public import Foundation

/// CLI-layer errors for MistDemo's `rereference-asset` command.
///
/// This type lives in MistDemo, not MistKit, on purpose. MistKit's
/// `CloudKitService.rereferenceAsset(...)` already `throws(CloudKitError)` for
/// every domain/transport failure; this enum does not duplicate or replace it.
/// Instead it covers concerns specific to the command-line front end:
/// - `sourceRecordRequired` / `assetFieldRequired` / `targetRecordRequired`
///   validate command-line arguments *before* MistKit is invoked.
/// - `operationFailed` wraps a `CloudKitError`'s `localizedDescription` caught
///   from `rereferenceAsset(...)` (see `RereferenceAssetCommand`), surfacing it
///   as a flat user-facing message.
///
/// This mirrors the established demo pattern shared by `DeleteError`,
/// `UploadAssetError`, etc. — "input-validation cases + `operationFailed(String)`
/// wrapper" — which keeps CLI presentation concerns out of the library.
public enum RereferenceAssetError: Error, LocalizedError {
  case sourceRecordRequired
  case assetFieldRequired
  case targetRecordRequired
  case operationFailed(String)

  /// A localized description of the error.
  public var errorDescription: String? {
    switch self {
    case .sourceRecordRequired:
      return "Source record is required. Specify with --source-record <name>"
    case .assetFieldRequired:
      return "Asset field is required. Specify with --asset-field <field>"
    case .targetRecordRequired:
      return "Target record is required. Specify with --target-record <name>"
    case .operationFailed(let message):
      return "Re-reference operation failed: \(message)"
    }
  }
}

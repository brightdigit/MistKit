//
//  CloudKitError+ZoneErrorDescription.swift
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

extension CloudKitError {
  /// Renders a per-zone operation failure into a human-readable description.
  ///
  /// Split out of `CloudKitError+ErrorDescription.swift` to keep that file
  /// within the file-length limit.
  internal static func zoneOperationDescription(_ zoneError: ZoneOperationFailure) -> String {
    let identifier = zoneError.identifier
    let code = zoneError.serverErrorCode.rawValue
    var message = "CloudKit zone operation failed for '\(identifier)' (\(code))"
    if let reason = zoneError.reason {
      message += "\nReason: \(reason)"
    }
    return message
  }

  /// Describes exhausting the zone-changes pagination ceiling.
  internal static func zonePaginationDescription(
    maxPages: Int,
    zoneCount: Int
  ) -> String {
    "CloudKit zone-changes exceeded pagination limit of \(maxPages) pages "
      + "(collected \(zoneCount) zones)"
  }
}

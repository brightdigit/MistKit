//
//  UpdateSummary.swift
//  CelestraCloud
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

internal import CelestraCloudKit

/// Tracks update operation statistics
internal struct UpdateSummary {
  internal var successCount = 0
  internal var errorCount = 0
  internal var skippedCount = 0
  internal var notModifiedCount = 0
  internal var articlesCreated = 0
  internal var articlesUpdated = 0

  internal mutating func record(_ result: FeedUpdateResult) {
    switch result {
    case .success(let created, let updated):
      successCount += 1
      articlesCreated += created
      articlesUpdated += updated
    case .notModified:
      notModifiedCount += 1
    case .skipped:
      skippedCount += 1
    case .error:
      errorCount += 1
    }
  }
}

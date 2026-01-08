//
//  OperationClassification.swift
//  BushelCloud
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

import Foundation

/// Classifies CloudKit operations as creates or updates
///
/// Since CloudKit's `.forceReplace` operation doesn't distinguish between
/// creating new records and updating existing ones, we pre-fetch existing
/// record names and classify operations before execution.
public struct OperationClassification: Sendable {
  /// Record names that will be created (don't exist in CloudKit)
  public let creates: Set<String>

  /// Record names that will be updated (already exist in CloudKit)
  public let updates: Set<String>

  /// Initialize by comparing proposed records against existing records
  ///
  /// - Parameters:
  ///   - proposedRecords: Record names we want to sync
  ///   - existingRecords: Record names that already exist in CloudKit
  public init(proposedRecords: [String], existingRecords: Set<String>) {
    var creates = Set<String>()
    var updates = Set<String>()

    for recordName in proposedRecords {
      if existingRecords.contains(recordName) {
        updates.insert(recordName)
      } else {
        creates.insert(recordName)
      }
    }

    self.creates = creates
    self.updates = updates
  }
}

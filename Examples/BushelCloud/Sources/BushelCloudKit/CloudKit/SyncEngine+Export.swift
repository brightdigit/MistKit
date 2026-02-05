//
//  SyncEngine+Export.swift
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

import BushelLogging
import BushelUtilities
import Logging
public import MistKit

#if canImport(FelinePineSwift)
  import FelinePineSwift
#endif

// MARK: - Export Operations

extension SyncEngine {
  // MARK: - Export Result Type

  public struct ExportResult {
    public let restoreImages: [RecordInfo]
    public let xcodeVersions: [RecordInfo]
    public let swiftVersions: [RecordInfo]

    public init(
      restoreImages: [RecordInfo], xcodeVersions: [RecordInfo], swiftVersions: [RecordInfo]
    ) {
      self.restoreImages = restoreImages
      self.xcodeVersions = xcodeVersions
      self.swiftVersions = swiftVersions
    }
  }

  /// Export all records from CloudKit to a structured format
  public func export() async throws -> ExportResult {
    ConsoleOutput.print("\n" + String(repeating: "=", count: 60))
    BushelUtilities.ConsoleOutput.info("Exporting data from CloudKit")
    ConsoleOutput.print(String(repeating: "=", count: 60))
    Self.logger.info("Exporting CloudKit data")

    Self.logger.debug(
      "Using MistKit queryRecords() to fetch all records of each type from the public database"
    )

    ConsoleOutput.print("\n📥 Fetching RestoreImage records...")
    Self.logger.debug(
      "Querying CloudKit for recordType: 'RestoreImage' with limit: 200"
    )
    let restoreImages = try await cloudKitService.queryRecords(recordType: "RestoreImage")
    Self.logger.debug(
      "Retrieved \(restoreImages.count) RestoreImage records"
    )

    ConsoleOutput.print("📥 Fetching XcodeVersion records...")
    Self.logger.debug(
      "Querying CloudKit for recordType: 'XcodeVersion' with limit: 200"
    )
    let xcodeVersions = try await cloudKitService.queryRecords(recordType: "XcodeVersion")
    Self.logger.debug(
      "Retrieved \(xcodeVersions.count) XcodeVersion records"
    )

    ConsoleOutput.print("📥 Fetching SwiftVersion records...")
    Self.logger.debug(
      "Querying CloudKit for recordType: 'SwiftVersion' with limit: 200"
    )
    let swiftVersions = try await cloudKitService.queryRecords(recordType: "SwiftVersion")
    Self.logger.debug(
      "Retrieved \(swiftVersions.count) SwiftVersion records"
    )

    ConsoleOutput.print("\n✅ Exported:")
    ConsoleOutput.print("   • \(restoreImages.count) restore images")
    ConsoleOutput.print("   • \(xcodeVersions.count) Xcode versions")
    ConsoleOutput.print("   • \(swiftVersions.count) Swift versions")

    Self.logger.debug(
      """
      MistKit returns RecordInfo structs with record metadata. \
      Use .fields to access CloudKit field values.
      """
    )

    return ExportResult(
      restoreImages: restoreImages,
      xcodeVersions: xcodeVersions,
      swiftVersions: swiftVersions
    )
  }
}

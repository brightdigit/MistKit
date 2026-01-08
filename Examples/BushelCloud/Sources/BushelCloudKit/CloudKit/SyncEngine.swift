//
//  SyncEngine.swift
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

public import BushelFoundation
public import BushelLogging
public import BushelUtilities
public import Foundation
import Logging
public import MistKit

#if canImport(FelinePineSwift)
  import FelinePineSwift
#endif

/// Orchestrates the complete sync process from data sources to CloudKit
///
/// **Tutorial**: This demonstrates the typical flow for CloudKit data syncing:
/// 1. Fetch data from external sources
/// 2. Transform to CloudKit records
/// 3. Batch upload using MistKit
///
/// Use `--verbose` flag to see detailed MistKit API usage.
public struct SyncEngine: Sendable {
  // MARK: - Configuration

  public struct SyncOptions: Sendable {
    public var dryRun: Bool = false
    public var pipelineOptions: DataSourcePipeline.Options = .init()

    public init(dryRun: Bool = false, pipelineOptions: DataSourcePipeline.Options = .init()) {
      self.dryRun = dryRun
      self.pipelineOptions = pipelineOptions
    }
  }

  // MARK: - Result Types

  public struct SyncResult: Sendable {
    public let restoreImagesCount: Int
    public let xcodeVersionsCount: Int
    public let swiftVersionsCount: Int

    public init(restoreImagesCount: Int, xcodeVersionsCount: Int, swiftVersionsCount: Int) {
      self.restoreImagesCount = restoreImagesCount
      self.xcodeVersionsCount = xcodeVersionsCount
      self.swiftVersionsCount = swiftVersionsCount
    }
  }

  /// Detailed sync result with per-type breakdown of creates/updates/failures
  public struct DetailedSyncResult: Sendable, Codable {
    public let restoreImages: TypeSyncResult
    public let xcodeVersions: TypeSyncResult
    public let swiftVersions: TypeSyncResult

    public init(
      restoreImages: TypeSyncResult, xcodeVersions: TypeSyncResult, swiftVersions: TypeSyncResult
    ) {
      self.restoreImages = restoreImages
      self.xcodeVersions = xcodeVersions
      self.swiftVersions = swiftVersions
    }

    /// Convert to JSON string
    public func toJSON(pretty: Bool = false) throws -> String {
      let encoder = JSONEncoder()
      if pretty {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      }
      let data = try encoder.encode(self)
      return String(data: data, encoding: .utf8) ?? ""
    }
  }

  /// Per-type sync statistics
  public struct TypeSyncResult: Sendable, Codable {
    public let created: Int
    public let updated: Int
    public let failed: Int
    public let failedRecordNames: [String]

    public var total: Int {
      created + updated + failed
    }

    public var succeeded: Int {
      created + updated
    }

    public init(created: Int, updated: Int, failed: Int, failedRecordNames: [String]) {
      self.created = created
      self.updated = updated
      self.failed = failed
      self.failedRecordNames = failedRecordNames
    }
  }

  // MARK: - Properties

  internal let cloudKitService: BushelCloudKitService
  internal let pipeline: DataSourcePipeline

  // MARK: - Initialization

  /// Initialize sync engine with CloudKit credentials
  ///
  /// **Flexible Authentication**: Supports both file-based and string-based PEM content:
  /// - `.pemString`: For CI/CD environments (GitHub Actions secrets)
  /// - `.pemFile`: For local development (file on disk)
  ///
  /// **Environment Separation**: Use separate keys for development and production:
  /// - Development: Safe for testing, free API calls, can clear data freely
  /// - Production: Real user data, requires careful key management
  ///
  /// - Parameters:
  ///   - containerIdentifier: CloudKit container ID
  ///   - keyID: Server-to-Server Key ID
  ///   - authMethod: Authentication method (`.pemString` or `.pemFile`)
  ///   - environment: CloudKit environment (.development or .production, defaults to .development)
  ///   - configuration: Fetch configuration for data sources
  /// - Throws: Error if authentication credentials are invalid or missing
  public init(
    containerIdentifier: String,
    keyID: String,
    authMethod: CloudKitAuthMethod,
    environment: Environment = .development,
    configuration: FetchConfiguration = FetchConfiguration.loadFromEnvironment()
  ) throws {
    // Initialize CloudKit service based on auth method
    let service: BushelCloudKitService
    switch authMethod {
    case .pemString(let pem):
      service = try BushelCloudKitService(
        containerIdentifier: containerIdentifier,
        keyID: keyID,
        pemString: pem,
        environment: environment
      )
    case .pemFile(let path):
      service = try BushelCloudKitService(
        containerIdentifier: containerIdentifier,
        keyID: keyID,
        privateKeyPath: path,
        environment: environment
      )
    }

    self.cloudKitService = service
    self.pipeline = DataSourcePipeline(
      configuration: configuration
    )
  }

  // MARK: - Sync Operations

  /// Execute full sync from all data sources to CloudKit
  ///
  /// This method now tracks detailed statistics about creates, updates, and failures
  /// for each record type, providing better visibility into sync operations.
  ///
  /// - Parameter options: Sync options including dry-run mode
  /// - Returns: Detailed sync result with per-type breakdown
  public func sync(options: SyncOptions = SyncOptions()) async throws -> DetailedSyncResult {
    ConsoleOutput.print("\n" + String(repeating: "=", count: 60))
    BushelUtilities.ConsoleOutput.info("Starting Bushel CloudKit Sync")
    ConsoleOutput.print(String(repeating: "=", count: 60))
    Self.logger.info("Sync started")

    if options.dryRun {
      BushelUtilities.ConsoleOutput.info("DRY RUN MODE - No changes will be made to CloudKit")
      Self.logger.info("Sync running in dry-run mode")
    }

    Self.logger.debug(
      "Using MistKit Server-to-Server authentication for bulk record operations"
    )

    // Step 1: Fetch from all data sources
    ConsoleOutput.print("\n📥 Step 1: Fetching data from external sources...")
    Self.logger.debug(
      "Initializing data source pipeline to fetch from ipsw.me, TheAppleWiki, MESU, and other sources"
    )

    let fetchResult = try await pipeline.fetch(options: options.pipelineOptions)

    Self.logger.debug(
      "Data fetch complete. Beginning deduplication and merge phase."
    )
    Self.logger.debug(
      "Multiple data sources may have overlapping data. The pipeline deduplicates by version+build number."
    )

    let totalRecords =
      fetchResult.restoreImages.count + fetchResult.xcodeVersions.count
      + fetchResult.swiftVersions.count

    ConsoleOutput.print("\n📊 Data Summary:")
    ConsoleOutput.print("   RestoreImages: \(fetchResult.restoreImages.count)")
    ConsoleOutput.print("   XcodeVersions: \(fetchResult.xcodeVersions.count)")
    ConsoleOutput.print("   SwiftVersions: \(fetchResult.swiftVersions.count)")
    ConsoleOutput.print("   ─────────────────────")
    ConsoleOutput.print("   Total: \(totalRecords) records")

    Self.logger.debug(
      "Records ready for CloudKit upload: \(totalRecords) total"
    )

    // Step 2: Sync to CloudKit (unless dry run)
    if !options.dryRun {
      print("\n☁️  Step 2: Syncing to CloudKit...")
      Self.logger.debug(
        "Using MistKit to batch upload records to CloudKit public database"
      )

      // Pre-fetch existing records in parallel
      print("   Pre-fetching existing records for create/update classification...")
      async let existingSwift = cloudKitService.fetchExistingRecordNames(
        recordType: SwiftVersionRecord.cloudKitRecordType
      )
      async let existingRestore = cloudKitService.fetchExistingRecordNames(
        recordType: RestoreImageRecord.cloudKitRecordType
      )
      async let existingXcode = cloudKitService.fetchExistingRecordNames(
        recordType: XcodeVersionRecord.cloudKitRecordType
      )

      let (swiftNames, restoreNames, xcodeNames) = try await (
        existingSwift, existingRestore, existingXcode
      )

      Self.logger.debug(
        """
        Pre-fetch complete: \(swiftNames.count) Swift, \
        \(restoreNames.count) Restore, \(xcodeNames.count) Xcode
        """
      )

      // Classify operations for each type
      let swiftClassification = OperationClassification(
        proposedRecords: fetchResult.swiftVersions.map(\.recordName),
        existingRecords: swiftNames
      )
      let restoreClassification = OperationClassification(
        proposedRecords: fetchResult.restoreImages.map(\.recordName),
        existingRecords: restoreNames
      )
      let xcodeClassification = OperationClassification(
        proposedRecords: fetchResult.xcodeVersions.map(\.recordName),
        existingRecords: xcodeNames
      )

      Self.logger.debug(
        "Classification complete. Ready to sync in dependency order."
      )

      // Sync each type with classification tracking (in dependency order)
      // SwiftVersion and RestoreImage first (no dependencies)
      // XcodeVersion last (references the other two)
      let swiftResult = try await syncRecords(
        fetchResult.swiftVersions,
        classification: swiftClassification
      )
      let restoreResult = try await syncRecords(
        fetchResult.restoreImages,
        classification: restoreClassification
      )
      let xcodeResult = try await syncRecords(
        fetchResult.xcodeVersions,
        classification: xcodeClassification
      )

      print("\n" + String(repeating: "=", count: 60))
      BushelUtilities.ConsoleOutput.success("Sync completed successfully!")
      print(String(repeating: "=", count: 60))
      Self.logger.info("Sync completed successfully")

      return DetailedSyncResult(
        restoreImages: restoreResult,
        xcodeVersions: xcodeResult,
        swiftVersions: swiftResult
      )
    } else {
      print("\n⏭️  Step 2: Skipped (dry run)")
      print("   Would sync:")
      print("   • \(fetchResult.restoreImages.count) restore images")
      print("   • \(fetchResult.xcodeVersions.count) Xcode versions")
      print("   • \(fetchResult.swiftVersions.count) Swift versions")
      Self.logger.debug(
        "Dry run mode: No CloudKit operations performed"
      )

      print("\n" + String(repeating: "=", count: 60))
      BushelUtilities.ConsoleOutput.success("Dry run completed!")
      print(String(repeating: "=", count: 60))

      // Return empty result for dry run
      return DetailedSyncResult(
        restoreImages: TypeSyncResult(created: 0, updated: 0, failed: 0, failedRecordNames: []),
        xcodeVersions: TypeSyncResult(created: 0, updated: 0, failed: 0, failedRecordNames: []),
        swiftVersions: TypeSyncResult(created: 0, updated: 0, failed: 0, failedRecordNames: [])
      )
    }
  }

  /// Helper method to sync one record type
  ///
  /// This replaces the use of MistKit's `syncAllRecords()` extension method,
  /// giving us full control over result tracking.
  ///
  /// - Parameters:
  ///   - records: Records to sync
  ///   - classification: Classification of operations as creates vs updates
  /// - Returns: Sync result for this record type
  private func syncRecords<T: CloudKitRecord>(
    _ records: [T],
    classification: OperationClassification
  ) async throws -> TypeSyncResult {
    guard !records.isEmpty else {
      return TypeSyncResult(created: 0, updated: 0, failed: 0, failedRecordNames: [])
    }

    let operations = records.map { record in
      RecordOperation(
        operationType: .forceReplace,
        recordType: T.cloudKitRecordType,
        recordName: record.recordName,
        fields: record.toCloudKitFields()
      )
    }

    return try await cloudKitService.executeBatchOperations(
      operations,
      recordType: T.cloudKitRecordType,
      classification: classification
    )
  }

  /// Delete all records from CloudKit
  public func clear() async throws {
    ConsoleOutput.print("\n" + String(repeating: "=", count: 60))
    BushelUtilities.ConsoleOutput.info("Clearing all CloudKit data")
    ConsoleOutput.print(String(repeating: "=", count: 60))
    Self.logger.info("Clearing all CloudKit records")

    try await cloudKitService.deleteAllRecords()

    ConsoleOutput.print("\n" + String(repeating: "=", count: 60))
    BushelUtilities.ConsoleOutput.success("Clear completed successfully!")
    ConsoleOutput.print(String(repeating: "=", count: 60))
    Self.logger.info("Clear completed successfully")
  }
}

// MARK: - Loggable Conformance
extension SyncEngine: Loggable {
  public static let loggingCategory: BushelLogging.Category = .application
}

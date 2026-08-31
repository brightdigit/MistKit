//
//  BushelCloudKitService.swift
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
public import Foundation
internal import Logging
public import MistKit

#if canImport(FelinePineSwift)
  internal import FelinePineSwift
#endif

/// CloudKit service wrapper for Bushel demo operations
///
/// **Tutorial**: This demonstrates MistKit's Server-to-Server authentication pattern:
/// 1. Load ECDSA private key from .pem file
/// 2. Create ServerToServerAuthManager with key ID and PEM string
/// 3. Initialize CloudKitService with the auth manager
/// 4. Use service.modifyRecords() and service.queryAllRecords() for operations
///
/// This pattern allows command-line tools and servers to access CloudKit without user authentication.
public struct BushelCloudKitService: Sendable, RecordManaging, CloudKitRecordCollection {
  public typealias RecordTypeSetType = RecordTypeSet

  // MARK: - CloudKitRecordCollection

  /// All CloudKit record types managed by this service (using variadic generics)
  public static let recordTypes = RecordTypeSet(
    RestoreImageRecord.self,
    XcodeVersionRecord.self,
    SwiftVersionRecord.self,
    DataSourceMetadata.self
  )

  private let service: CloudKitService

  // MARK: - Initialization

  /// Initialize CloudKit service with Server-to-Server authentication
  ///
  /// **MistKit Pattern**: Server-to-Server authentication requires:
  /// 1. Key ID from CloudKit Dashboard → API Access → Server-to-Server Keys
  /// 2. A private key, either the downloaded `.pem` file or its contents
  /// 3. Container identifier (begins with "iCloud.")
  ///
  /// `PrivateKeyMaterial` covers both the local-development case
  /// (`.file(path:)`) and the CI case (`.raw`, from a secret), so no temporary
  /// file is needed in GitHub Actions. MistKit defers reading a `.file(path:)`
  /// key until the credentials are consumed, so this initializer does no file
  /// IO and a missing file surfaces on first use.
  ///
  /// - Parameters:
  ///   - containerIdentifier: CloudKit container ID (e.g., "iCloud.com.company.App")
  ///   - keyID: Server-to-Server Key ID from CloudKit Dashboard
  ///   - privateKey: Signing key, inline PEM or a path to a `.pem` file
  ///   - environment: CloudKit environment (.development or .production, defaults to .development)
  /// - Throws: ``CredentialValidationError`` if the key ID or inline PEM is malformed.
  public init(
    containerIdentifier: String,
    keyID: String,
    privateKey: PrivateKeyMaterial,
    environment: Environment = .development
  ) throws {
    // Validate before MistKit sees them: these produce far better messages
    // than a downstream signing failure.
    try KeyIDValidator.validate(keyID)
    if case .raw(let pem) = privateKey {
      try PEMValidator.validate(pem)
    }

    self.service = CloudKitService(
      containerIdentifier: containerIdentifier,
      credentials: try Credentials(
        serverToServer: ServerToServerCredentials(keyID: keyID, privateKey: privateKey)
      ),
      environment: environment
    )
  }

  // MARK: - RecordManaging Protocol Requirements

  /// Query all records of a given type, automatically paginating
  public func queryAllRecords(recordType: String) async throws -> [RecordInfo] {
    try await service.queryAllRecords(
      recordType: recordType,
      database: .public(.prefers(.serverToServer))
    )
  }

  /// Fetch existing record names for create/update classification
  ///
  /// This method queries CloudKit to get all existing record names for a given type.
  /// Used to classify sync operations as creates (new records) vs updates (existing records).
  ///
  /// - Parameter recordType: The CloudKit record type to query
  /// - Returns: Set of existing record names in CloudKit
  public func fetchExistingRecordNames(recordType: String) async throws -> Set<String> {
    Self.logger.debug("Pre-fetching existing record names for \(recordType)")

    let records = try await service.queryAllRecords(
      recordType: recordType,
      desiredKeys: [],
      database: .public(.prefers(.serverToServer))
    )
    let recordNames = Set(records.map(\.recordName))

    Self.logger.debug("Found \(recordNames.count) existing \(recordType) records")
    return recordNames
  }

  /// Execute operations in batches without tracking creates/updates
  ///
  /// This is the protocol-conforming version that doesn't track create vs update.
  /// For detailed tracking, use the overload with `classification` parameter.
  public func executeBatchOperations(_ operations: [RecordOperation]) async throws {
    guard let recordType = operations.first?.recordType else {
      Self.logger.debug("executeBatchOperations called with no operations; nothing to do")
      return
    }
    let classification = OperationClassification(proposedRecordNames: [], existingRecordNames: [])
    _ = try await executeBatchOperations(
      operations, recordType: recordType, classification: classification
    )
  }

  /// Execute operations in batches with detailed create/update tracking
  ///
  /// **MistKit Pattern**: CloudKit has a 200 operations/request limit.
  /// This method chunks operations and calls service.modifyRecords() for each batch.
  ///
  /// - Parameters:
  ///   - operations: CloudKit operations to execute
  ///   - recordType: Record type name for logging
  ///   - classification: Pre-computed classification of operations as creates vs updates
  /// - Returns: Detailed sync result with creates/updates/failures breakdown
  public func executeBatchOperations(
    _ operations: [RecordOperation],
    recordType: String,
    classification: OperationClassification
  ) async throws -> SyncEngine.TypeSyncResult {
    let batchSize = 200
    let batches = stride(from: 0, to: operations.count, by: batchSize).map {
      Array(operations[$0..<Swift.min($0 + batchSize, operations.count)])
    }

    ConsoleOutput.print(
      "Syncing \(operations.count) \(recordType) record(s) in \(batches.count) batch(es)...")
    Self.logger.debug(
      """
      CloudKit batch limit: 200 operations/request. \
      Using \(batches.count) batch(es) for \(operations.count) records.
      """
    )
    Self.logger.debug(
      "Classification: \(classification.creates.count) creates, \(classification.updates.count) updates"
    )

    var totalCreated = 0
    var totalUpdated = 0
    var totalFailed = 0
    var failedRecordNames: [String] = []

    for (index, batch) in batches.enumerated() {
      print("  Batch \(index + 1)/\(batches.count): \(batch.count) records...")
      Self.logger.debug(
        "Calling MistKit service.modifyRecords() with \(batch.count) RecordOperation objects"
      )

      // MistKit partitions the results into created/updated/failed for us based on
      // the pre-computed classification. Note: it does NOT chunk, so we keep our own
      // 200-op batching above and hand it one batch at a time.
      let batchResult = try await service.modifyRecords(
        batch,
        classification: classification,
        database: .public(.prefers(.serverToServer))
      )

      Self.logger.debug(
        "Received \(batchResult.totalCount) per-record results from CloudKit"
      )

      // Accumulate totals. We intentionally ignore MistKit's `unclassified` bucket
      // (successes whose record name is in neither set) to preserve the historical
      // created + updated == succeeded semantics of TypeSyncResult.
      let batchFailed = batchResult.failedCount
      let batchSucceeded = batchResult.createdCount + batchResult.updatedCount
      totalCreated += batchResult.createdCount
      totalUpdated += batchResult.updatedCount
      totalFailed += batchFailed

      // The counts above deliberately drop MistKit's `unclassified` bucket, so
      // created + updated + failed can be < totalCount. Log when that happens so
      // the summary totals don't look like silent data loss while debugging.
      let batchUnclassified =
        batchResult.totalCount - batchResult.createdCount - batchResult.updatedCount - batchFailed
      if batchUnclassified > 0 {
        Self.logger.debug(
          "\(batchUnclassified) record(s) in MistKit's 'unclassified' bucket; excluded from totals."
        )
      }

      for failure in batchResult.failed {
        failedRecordNames.append(failure.identifier)
        Self.logger.debug(
          "Error: recordName=\(failure.identifier), code=\(failure.serverErrorCode.rawValue)"
        )
      }

      if batchFailed > 0 {
        print("   ⚠️  \(batchFailed) operations failed (see verbose logs for details)")
        print("   ✓ \(batchSucceeded) records confirmed")
      } else {
        Self.logger.info(
          "CloudKit confirmed \(batchSucceeded) records"
        )
      }
    }

    ConsoleOutput.print("\n📊 \(recordType) Sync Summary:")
    ConsoleOutput.print("   ✨ Created: \(totalCreated) records")
    ConsoleOutput.print("   🔄 Updated: \(totalUpdated) records")
    if totalFailed > 0 {
      print("   ❌ Failed: \(totalFailed) operations")
      Self.logger.debug(
        "Use --verbose flag to see CloudKit error details (serverErrorCode, reason, etc.)"
      )
    }

    return SyncEngine.TypeSyncResult(
      created: totalCreated,
      updated: totalUpdated,
      failed: totalFailed,
      failedRecordNames: failedRecordNames
    )
  }
}

// MARK: - Loggable Conformance
extension BushelCloudKitService: Loggable {
  public static let loggingCategory: BushelLogging.Category = .data
}

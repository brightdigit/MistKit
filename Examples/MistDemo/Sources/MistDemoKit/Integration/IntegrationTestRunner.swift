//
//  IntegrationTestRunner.swift
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

import Foundation
import MistKit

/// Orchestrates comprehensive integration tests for CloudKit operations
struct IntegrationTestRunner {
  let service: CloudKitService
  let containerIdentifier: String
  let database: MistKit.Database
  let recordCount: Int
  let assetSizeKB: Int
  let skipCleanup: Bool
  let verbose: Bool

  // MARK: - Public Workflows

  /// Run the public-database workflow covering all non-user-scoped API methods.
  func runBasicWorkflow() async throws {
    printWorkflowHeader()
    try await runCorePhases(service: service)
    printSuccessSummary(includeUserPhases: false)
  }

  /// Run the private-database workflow covering all API methods including user-identity endpoints.
  func runPrivateWorkflow() async throws {
    printWorkflowHeader()
    try await runCorePhases(service: service)
    let userInfo = try await phaseFetchCurrentUser(service: service)
    try await phaseDiscoverUserIdentities(service: service, userRecordName: userInfo.userRecordName)
    printSuccessSummary(includeUserPhases: true)
  }

  // MARK: - Core Phase Runner

  // swiftlint:disable:next cyclomatic_complexity
  private func runCorePhases(service: CloudKitService) async throws {
    var createdRecordNames: [String] = []
    var syncToken: String?

    do {
      if database == .private {
        try await phaseListZones(service: service)
      }
      try await phaseLookupZone(service: service)
      if database == .private {
        try await phaseFetchZoneChanges(service: service)
      }
      let assetToken = try await phase3UploadAsset(service: service)
      createdRecordNames = try await phase4CreateRecords(service: service, assetToken: assetToken)
      try await phaseQueryRecords(service: service, createdRecordNames: createdRecordNames)
      try await phaseLookupRecords(service: service, recordNames: createdRecordNames)
      if database == .private {
        syncToken = try await phase7InitialSync(
          service: service, createdRecordNames: createdRecordNames)
      }
      try await phase8ModifyRecords(service: service, createdRecordNames: createdRecordNames)
      if database == .private {
        try await phase9IncrementalSync(
          service: service, syncToken: syncToken, createdRecordNames: createdRecordNames)
      }
      try await phase10FinalVerification(service: service)
      if !skipCleanup {
        try await phase11Cleanup(service: service, createdRecordNames: createdRecordNames)
      } else {
        printSkippedCleanup(recordNames: createdRecordNames)
      }
    } catch {
      print("\n❌ Error: \(error)")
      if !createdRecordNames.isEmpty && !skipCleanup {
        print("\n⚠️  Attempting cleanup of \(createdRecordNames.count) test records...")
        try? await phase11Cleanup(service: service, createdRecordNames: createdRecordNames)
      }
      throw error
    }
  }
}

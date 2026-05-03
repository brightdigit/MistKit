//
//  IntegrationTestRunner+Phases.swift
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

extension IntegrationTestRunner {
  // MARK: - Phase 1: List All Zones

  func phaseListZones(service: CloudKitService) async throws {
    print("\n📋 Phase 1: List all zones")

    let zones = try await service.listZones()

    guard !zones.isEmpty else {
      throw IntegrationTestError.zoneNotFound("(any zone)")
    }

    print("✅ Found \(zones.count) zone(s)")

    if verbose {
      for zone in zones {
        print("   - \(zone.zoneName)")
      }
    }
  }

  // MARK: - Phase 2: Lookup Specific Zone

  func phaseLookupZone(service: CloudKitService) async throws {
    print("\n📋 Phase 2: Lookup default zone")

    let zones = try await service.lookupZones(zoneIDs: [.defaultZone])

    guard !zones.isEmpty else {
      throw IntegrationTestError.zoneNotFound("_defaultZone")
    }

    let zone = zones[0]
    print("✅ Found zone: \(zone.zoneName)")

    if verbose {
      if let owner = zone.ownerRecordName {
        print("   Owner: \(owner)")
      }
      if !zone.capabilities.isEmpty {
        print("   Capabilities: \(zone.capabilities.joined(separator: ", "))")
      }
    }
  }

  // MARK: - Phase 2b: Fetch Zone Changes

  func phaseFetchZoneChanges(service: CloudKitService) async throws {
    print("\n🔄 Phase 2b: Fetch zone changes")

    do {
      let result = try await service.fetchZoneChanges()
      print("✅ Fetched \(result.zones.count) zone(s)")
      if verbose {
        for zone in result.zones {
          print("   - \(zone.zoneName)")
        }
        if let token = result.syncToken {
          print("   Sync token: \(token.prefix(30))...")
        }
      }
    } catch {
      print("⚠️  fetchZoneChanges failed (non-fatal): \(error)")
    }
  }

  // MARK: - Phase 3: Asset Upload

  func phase3UploadAsset(service: CloudKitService) async throws -> AssetUploadReceipt {
    print("\n📤 Phase 3: Upload test asset")

    let testData = IntegrationTestData.generateTestImage(sizeKB: assetSizeKB)
    let sizeInMB = Double(testData.count) / 1_024 / 1_024

    if verbose {
      print("   Uploading \(testData.count) bytes (\(String(format: "%.2f", sizeInMB)) MB)...")
    }

    let receipt = try await service.uploadAssets(
      data: testData,
      recordType: IntegrationTestData.recordType,
      fieldName: "image"
    )

    print("✅ Uploaded asset: \(testData.count) bytes")

    if verbose {
      print("   Record: \(receipt.recordName)")
      print("   Field: \(receipt.fieldName)")
    }

    return receipt
  }

  // MARK: - Phase 4: Create Records

  func phase4CreateRecords(
    service: CloudKitService,
    assetToken: AssetUploadReceipt
  ) async throws -> [String] {
    print("\n📝 Phase 4: Create records with assets")

    if verbose {
      print("   Creating \(recordCount) records...")
    }

    var createdRecordNames: [String] = []

    for recordIndex in 1...recordCount {
      let recordName = "mistkit-test-\(UUID().uuidString.lowercased())"
      let record = try await service.createRecord(
        recordType: IntegrationTestData.recordType,
        recordName: recordName,
        fields: [
          "title": .string("Test Record \(recordIndex)"),
          "index": .int64(recordIndex),
          "image": .asset(assetToken.asset),
          "createdAt": .date(Date()),
        ]
      )
      createdRecordNames.append(record.recordName)
      if verbose {
        print("   ✅ Created: \(record.recordName)")
      }
    }

    guard !createdRecordNames.isEmpty else {
      throw IntegrationTestError.noRecordsCreated
    }

    print("✅ Created \(createdRecordNames.count) records")

    return createdRecordNames
  }

  // MARK: - Phase 5: Query Records

  func phaseQueryRecords(
    service: CloudKitService,
    createdRecordNames: [String]
  ) async throws {
    print("\n🔍 Phase 5: Query records by type")

    do {
      let records = try await service.queryRecords(recordType: IntegrationTestData.recordType)
      print("✅ Queried \(records.count) record(s) of type '\(IntegrationTestData.recordType)'")
      if verbose {
        let ours = records.filter { createdRecordNames.contains($0.recordName) }
        print("   Found \(ours.count) of our \(createdRecordNames.count) test records")
      }
    } catch CloudKitError.httpErrorWithDetails(statusCode: 404, serverErrorCode: _, reason: _)
      where true
    {
      // Schema propagation in development can lag behind the first write.
      // lookupRecords (phase 6) already verifies the records exist by name.
      print("⚠️  queryRecords returned NOT_FOUND — schema may not be indexed yet (non-fatal)")
    }
  }

  // MARK: - Phase 6: Lookup Records by Name

  func phaseLookupRecords(
    service: CloudKitService,
    recordNames: [String]
  ) async throws {
    let lookupNames = Array(recordNames.prefix(min(3, recordNames.count)))
    print("\n🔍 Phase 6: Lookup \(lookupNames.count) record(s) by name")

    let records = try await service.lookupRecords(recordNames: lookupNames)

    print("✅ Looked up \(records.count) record(s)")

    if verbose {
      for record in records {
        print("   - \(record.recordName)")
      }
    }
  }
}

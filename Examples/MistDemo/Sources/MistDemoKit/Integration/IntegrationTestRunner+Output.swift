//
//  IntegrationTestRunner+Output.swift
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
  // MARK: - Helpers

  func printWorkflowHeader() {
    print("\n" + String(repeating: "=", count: 80))
    print("🧪 Integration Test Suite: CloudKit Operations")
    print(String(repeating: "=", count: 80))
    print("Container: \(containerIdentifier)")
    print("Database: \(database == .public ? "public" : "private")")
    print("Record Count: \(recordCount)")
    print("Asset Size: \(assetSizeKB) KB")
    print(String(repeating: "=", count: 80))
  }

  func printSkippedCleanup(recordNames: [String]) {
    print("\n⚠️  Skipping cleanup (--skip-cleanup flag set)")
    print("   Test records left in CloudKit:")
    for name in recordNames { print("   - \(name)") }
    print("\nTo manually cleanup these records:")
    print("   1. Visit https://icloud.developer.apple.com/dashboard/")
    print("   2. Select your container: \(containerIdentifier)")
    print("   3. Navigate to \(database == .public ? "Public" : "Private") Database → Records")
    print("   4. Search for record type: \(IntegrationTestData.recordType)")
  }

  // swiftlint:disable:next function_body_length
  func printSuccessSummary(includeUserPhases: Bool) {
    print("\n" + String(repeating: "=", count: 80))
    print("✅ Integration Test Complete!")
    print(String(repeating: "=", count: 80))
    print("\nPhases Completed:")
    if database == .private {
      print("  ✅ Phase  1: List all zones          (listZones)")
    } else {
      print("  ⏭️  Phase  1: List all zones          (listZones — private db only)")
    }
    print("  ✅ Phase  2: Lookup default zone     (lookupZones)")
    if database == .private {
      print("  ✅ Phase 2b: Fetch zone changes      (fetchZoneChanges)")
    } else {
      print("  ⏭️  Phase 2b: Fetch zone changes      (fetchZoneChanges — private db only)")
    }
    print("  ✅ Phase  3: Upload test asset       (uploadAssets)")
    print("  ✅ Phase  4: Create records          (createRecord)")
    print("  ✅ Phase  5: Query records by type   (queryRecords)")
    print("  ✅ Phase  6: Lookup records by name  (lookupRecords)")
    if database == .private {
      print("  ✅ Phase  7: Initial sync            (fetchRecordChanges)")
    } else {
      print("  ⏭️  Phase  7: Initial sync            (fetchRecordChanges — private db only)")
    }
    print("  ✅ Phase  8: Modify records          (updateRecord)")
    if database == .private {
      print("  ✅ Phase  9: Incremental sync        (fetchRecordChanges)")
    } else {
      print("  ⏭️  Phase  9: Incremental sync        (fetchRecordChanges — private db only)")
    }
    print("  ✅ Phase 10: Final zone check        (lookupZones)")
    if !skipCleanup {
      print("  ✅ Phase 11: Cleanup              (deleteRecord)")
    } else {
      print("  ⏭️  Phase 11: Cleanup skipped")
    }
    if includeUserPhases {
      print("  ✅ Phase 12: Fetch current user   (fetchCurrentUser)")
      print("  ✅ Phase 13: Discover identities  (discoverUserIdentities)")
    }
    print("\n💡 Next steps:")
    print("  • Run with --verbose for detailed output")
    print("  • Use --skip-cleanup to inspect records in CloudKit Console")
    if !includeUserPhases {
      print("  • Run 'mistdemo test-private' to also test user-identity APIs")
    }
  }
}

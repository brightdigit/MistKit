//
//  NativeCloudKitService.swift
//  MistDemoApp
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

import CloudKit
import Foundation

/// Thin wrapper around Apple's CloudKit framework that mirrors the read-side
/// operations the MistKit-driven MistDemo CLI exposes. The two demos hit the
/// same CloudKit container, so a presentation can flip between them and show
/// identical data accessed through different stacks.
@MainActor
final class NativeCloudKitService: ObservableObject {
    /// The shared demo container identifier — must match `MistDemoConfig.containerIdentifier`.
    static let demoContainerIdentifier = "iCloud.com.brightdigit.MistDemo"

    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var lastError: String?

    let containerIdentifier: String
    private let container: CKContainer

    init(containerIdentifier: String) {
        self.containerIdentifier = containerIdentifier
        self.container = CKContainer(identifier: containerIdentifier)
    }

    /// Convenience: which database we want to demo against. The MistDemo CLI
    /// defaults to `.private`, so mirror that here.
    var database: CKDatabase { container.privateCloudDatabase }

    func refreshAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            self.accountStatus = status
        } catch {
            self.accountStatus = .couldNotDetermine
            self.lastError = error.localizedDescription
        }
    }

    /// List all record zones in the private database (parity with `mistdemo lookup-zones`).
    func loadZones() async throws -> [ZoneRow] {
        let zones = try await database.allRecordZones()
        return zones.map(ZoneRow.init).sorted { $0.zoneName < $1.zoneName }
    }

    /// Run a `TRUEPREDICATE` query against the given record type
    /// (parity with `mistdemo query --record-type ...`).
    func queryRecords(recordType: String, limit: Int = 50) async throws -> [RecordRow] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: recordType, predicate: predicate)

        let (matchResults, _) = try await database.records(
            matching: query,
            inZoneWith: nil,
            desiredKeys: nil,
            resultsLimit: limit
        )

        return matchResults.compactMap { _, recordResult -> RecordRow? in
            switch recordResult {
            case .success(let record):
                return RecordRow(record)
            case .failure:
                return nil
            }
        }
    }
}

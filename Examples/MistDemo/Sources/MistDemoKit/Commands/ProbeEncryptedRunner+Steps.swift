//
//  ProbeEncryptedRunner+Steps.swift
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

internal import Foundation
internal import MistKit

extension ProbeEncryptedRunner {
  /// `zones/list` — proves the web-auth token reaches the private database
  /// at all before any encrypted-field step runs.
  internal mutating func probeZones() async {
    let name = "zones/list"
    let service = service
    let database = database
    let zones = await step(name) { try await service.listZones(database: database) }
    guard let zones else {
      return
    }
    let names = zones.map(\.zoneName).joined(separator: ", ")
    pass(name, "\(zones.count) zone(s): \(names)")
  }

  /// Uploads the probe asset, then force-replaces the encrypted record
  /// (with the asset attached) and its plain sibling.
  internal mutating func probeWrites() async {
    let receipt = await uploadProbeAsset()

    var fields: [String: FieldValue] = [
      "title": .string(.value("Encrypted probe")),
      "index": .int64(.value(0)),
      Self.secretField: .string(.value(Self.secretValue)),
    ]
    if let receipt {
      fields[Self.assetField] = .asset(.value(receipt.asset))
    }
    await modify(
      step: "records/modify forceReplace with isEncrypted",
      RecordOperation(
        operationType: .forceReplace,
        recordType: MistDemoConfig.recordType,
        recordName: config.recordName,
        fields: fields,
        encryptedFields: [Self.secretField]
      )
    )
    await modify(
      step: "records/modify forceReplace plain sibling",
      RecordOperation(
        operationType: .forceReplace,
        recordType: MistDemoConfig.recordType,
        recordName: plainRecordName,
        fields: ["title": .string(.value("Plain probe")), "index": .int64(.value(1))]
      )
    )
  }

  private mutating func uploadProbeAsset() async -> AssetUploadReceipt? {
    let name = "assets/upload + CDN PUT"
    let service = service
    let database = database
    let zoneID = zoneID
    let recordName = config.recordName
    let data = PNGData.generate(withSizeInKB: config.assetSizeKB)
    let receipt = await step(name) {
      try await service.uploadAssets(
        data: data,
        recordType: MistDemoConfig.recordType,
        fieldName: Self.assetField,
        recordName: recordName,
        zoneID: zoneID,
        database: database
      )
    }
    if let receipt {
      let checksum = receipt.asset.fileChecksum ?? "nil"
      pass(name, "uploaded \(data.count) bytes, fileChecksum \(checksum)")
    }
    return receipt
  }

  private mutating func modify(step name: String, _ operation: RecordOperation) async {
    let service = service
    let database = database
    let zoneID = zoneID
    let results = await step(name) {
      try await service.modifyRecords([operation], zoneID: zoneID, database: database)
    }
    guard let results else {
      return
    }
    report(results, step: name)
  }

  /// `records/lookup` has no zone parameter in MistKit, so it only runs
  /// against the default zone.
  internal mutating func probeLookup() async {
    let name = "records/lookup"
    guard zoneID == nil else {
      skip(name, "custom zone — lookupRecords has no zoneID parameter")
      return
    }
    let service = service
    let database = database
    let names = probeRecordNames
    let results = await step(name) {
      try await service.lookupRecords(recordNames: names, database: database)
    }
    guard let results else {
      return
    }
    report(results, step: name)
  }

  internal mutating func probeQuery() async {
    let name = "records/query"
    let service = service
    let database = database
    let zoneID = zoneID
    let query = Query(recordType: MistDemoConfig.recordType)
    let result = await step(name) {
      try await service.queryRecords(
        query, limit: 200, zoneID: zoneID, database: database
      )
    }
    guard let result else {
      return
    }
    reportFound(in: result.records, step: name)
  }

  /// CloudKit rejects `records/changes` against `_defaultZone` with
  /// BAD_REQUEST "cannot get changes in default zone" (verified live), so
  /// this step only runs with `--zone-name`.
  internal mutating func probeChanges() async {
    let name = "records/changes"
    guard zoneID != nil else {
      skip(name, "default zone — CloudKit cannot get changes in the default zone")
      return
    }
    let service = service
    let database = database
    let zoneID = zoneID
    let result = await step(name) {
      try await service.fetchRecordChanges(zoneID: zoneID, database: database)
    }
    guard let result else {
      return
    }
    reportFound(in: result.records, step: name)
  }

  /// B3 — assets become end-to-end encrypted under ADP as well.
  internal mutating func probeAssetDownload() async {
    let name = "asset downloadURL GET"
    guard let record = encryptedRecord else {
      skip(name, "encrypted record was not read back by any step")
      return
    }
    guard case .asset(.value(let asset))? = record.fields[Self.assetField] else {
      skip(name, "read-back record carries no '\(Self.assetField)' asset")
      return
    }
    let data = await step(name) { try await asset.download() }
    guard let data else {
      return
    }
    let declared = asset.size.map { "declared \($0)" } ?? "no declared size"
    pass(name, "\(data.count) bytes (\(declared))")
  }

  internal mutating func probeCleanup() async {
    let name = "records/modify forceDelete probe records"
    let operations = probeRecordNames.map { recordName in
      RecordOperation(
        operationType: .forceDelete,
        recordType: MistDemoConfig.recordType,
        recordName: recordName
      )
    }
    let service = service
    let database = database
    let zoneID = zoneID
    let results = await step(name) {
      try await service.modifyRecords(operations, zoneID: zoneID, database: database)
    }
    guard let results else {
      return
    }
    report(results, step: name)
  }
}

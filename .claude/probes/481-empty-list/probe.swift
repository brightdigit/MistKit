import Foundation
import MistKit

// Probe: how does CloudKit represent an EMPTY list field on the way back?
// Writes a record with an empty list + a populated list, then looks it up.

func env(_ key: String) -> String? {
  guard let path = try? String(contentsOfFile: "/Users/leo/Documents/Projects/MistKit/MistDemo.env", encoding: .utf8) else { return nil }
  for line in path.split(separator: "\n") {
    let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
    if parts.count == 2, parts[0].trimmingCharacters(in: .whitespaces) == key {
      return parts[1].trimmingCharacters(in: .whitespaces)
    }
  }
  return nil
}

let container = env("CLOUDKIT_CONTAINER_IDENTIFIER")!
let keyID = env("CLOUDKIT_KEY_ID")!
let keyPath = env("CLOUDKIT_PRIVATE_KEY_PATH")!

let creds = try Credentials(
  serverToServer: ServerToServerCredentials(keyID: keyID, privateKey: .file(path: keyPath))
)
let service = CloudKitService(
  containerIdentifier: container,
  credentials: creds,
  environment: .development
)

let suffix = Int(Date().timeIntervalSince1970)
let name = "emptylistprobe_\(suffix)"

print("=== WRITING record \(name) ===")
print("  probeEmptyList   = .list([])        (empty)")
print("  probeFilledList  = .list([.string]) (populated)")

do {
  let created = try await service.createRecord(
    recordType: "Note",
    recordName: name,
    fields: [
      "title": .string("empty list probe"),
      "probeEmptyList": .list([]),
      "probeFilledList": .list([.string("a"), .string("b")]),
    ],
    database: .public(.prefers(.serverToServer))
  )
  print("\n=== CREATE RESPONSE fields ===")
  for (k, v) in created.fields.sorted(by: { $0.key < $1.key }) {
    print("  \(k) = \(v)")
  }
  print("\n  probeEmptyList present in create response? \(created.fields["probeEmptyList"] != nil)")

  print("\n=== LOOKUP (read back) ===")
  let results = try await service.lookupRecords(recordNames: [name], database: .public(.prefers(.serverToServer)))
  for r in results {
    switch r {
    case .success(let rec):
      for (k, v) in rec.fields.sorted(by: { $0.key < $1.key }) {
        print("  \(k) = \(v)")
      }
      print("\n  >>> probeEmptyList present on read?  \(rec.fields["probeEmptyList"] != nil)")
      if let e = rec.fields["probeEmptyList"] {
        print("  >>> probeEmptyList value: \(e)")
      }
      print("  >>> probeFilledList value: \(rec.fields["probeFilledList"].map { "\($0)" } ?? "ABSENT")")
    case .failure(let err):
      print("  lookup failure: \(err)")
    }
  }
} catch {
  print("\n!!! ERROR: \(error)")
}

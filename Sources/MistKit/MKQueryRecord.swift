import Foundation

public protocol MKQueryRecord {
  static var recordType: String { get }
  static var desiredKeys: [String]? { get }

  var recordName: UUID? { get }
  var recordChangeTag: String? { get }
  var fields: [String: MKValue] { get }
  init(record: MKAnyRecord) throws
}

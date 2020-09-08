import Foundation

public protocol MKQueryRecord {
  static var recordType: String { get }
  static var desiredKeys: [String]? { get }

  var recordName: UUID { get }
  init(record: MKAnyRecord) throws
}

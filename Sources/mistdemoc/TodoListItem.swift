import Foundation
import MistKit

public struct TodoListItem: MKQueryRecord {
  public var fields: [String: MKValue] {
    return ["title": .string(title)]
  }

  public init(record: MKAnyRecord) throws {
    recordName = record.recordName
    recordChangeTag = record.recordChangeTag
    title = try record.string(fromKey: "title")
  }

  public init(title: String) {
    self.title = title
    recordName = nil
    recordChangeTag = nil
  }

  public static var recordType: String = "TodoItem"
  public static var desiredKeys: [String]? = ["title"]

  public let recordName: UUID?
  public let title: String
  public let recordChangeTag: String?
}

import Foundation
import MistKit

public class TodoListItem: MKQueryRecord {
  public var fields: [String: MKValue] {
    return ["title": .string(title)]
  }

  public required init(record: MKAnyRecord) throws {
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
  public var title: String
  public let recordChangeTag: String?
}

public extension Array where Element: MKQueryRecord {
  var information: String {
    let header = "\(count) results"
    let items = [header] + map { $0.information }
    let minlength = items.map { $0.components(separatedBy: .newlines).map { $0.count }.max() }.compactMap { $0 }.max() ?? 0
    let separator = String(repeating: "=", count: minlength + 3)
    return items.joined(separator: "\n\(separator)\n")
  }
}

public extension MKQueryRecord {
  var information: String {
    let fieldString = fields.map {
      "  \($0.key): \($0.value)"
    }.joined(separator: "\n")

    return """
    recordName: \(recordName?.uuidString ?? "")
    recordChangeTag: \(recordChangeTag ?? "")
    fields:
    \(fieldString)
    """
  }
}

import Foundation
import MistKit

public class TodoListItem: MKQueryRecord {
  public static let recordType: String = "TodoItem"
  public static let desiredKeys: [String] = [
    "title", "completedAt", "image", "location", "value"
  ]

  public let recordName: UUID?
  public let recordChangeTag: String?

  public var title: String
  public var completedAt: Date?
  public var image: MKAsset?
  public var value: Double?
  public var location: MKLocation?

  public var fields: [String: MKValue] {
    var fields: [String: MKValue] = ["title": .string(title)]
    if let completedAt = self.completedAt {
      fields["completedAt"] = .date(completedAt)
    }
    if let image = self.image {
      fields["image"] = .asset(image)
    }

    if let value = self.value {
      fields["value"] = .double(value)
    }

    if let location = self.location {
      fields["location"] = .location(location)
    }

    return fields
  }

  public required init(record: MKAnyRecord) throws {
    recordName = record.recordName
    recordChangeTag = record.recordChangeTag
    title = try record.string(fromKey: "title")
    completedAt = try record.dateIfExists(fromKey: "completedAt")
    image = try record.assetIfExists(fromKey: "image")
    location = try record.locationIfExists(fromKey: "location")
    value = try record.doubleIfExists(fromKey: "value")
  }

  public init(
    title: String,
    recordName: UUID? = nil,
    recordChangeTag: String? = nil
  ) {
    self.title = title
    self.recordName = recordName
    self.recordChangeTag = recordChangeTag
  }
}

public extension Array where Element: MKQueryRecord {
  var information: String {
    let header = "\(count) results"
    let items = [header] + map { $0.information }
    let minlength = items.map {
      $0.components(separatedBy: .newlines)
        .map { $0.count }
        .max()
    }
    .compactMap { $0 }
    .max() ?? 0
    let separator = String(repeating: "=", count: minlength + 3)
    return items.joined(separator: "\n\(separator)\n")
  }
}

public extension MKQueryRecord {
  var information: String {
    let fieldString = fields.map {
      "  \($0.key): \($0.value)"
    }
    .joined(separator: "\n")

    return """
    recordName: \(recordName?.uuidString ?? "")
    recordChangeTag: \(recordChangeTag ?? "")
    fields:
    \(fieldString)
    """
  }
}

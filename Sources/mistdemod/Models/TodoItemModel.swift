import MistKit
import MistKitDemo
import Vapor

public struct TodoItemModel: Content {
  public let id: UUID?
  public let title: String
  public init(item: TodoListItem) {
    title = item.title
    id = item.recordName
  }
}

extension TodoListItem: MKContentRecord {
  public typealias ContentType = TodoItemModel

  public static func content(fromRecord record: TodoListItem) -> TodoItemModel {
    TodoItemModel(item: record)
  }
}

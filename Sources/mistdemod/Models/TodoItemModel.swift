import MistKit
import MistKitDemo
import Vapor

public struct TodoItemModel: Content {
  let id: UUID?
  let title: String
  init(item: TodoListItem) {
    title = item.title
    id = item.recordName
  }
}

extension TodoListItem: MKContentRecord {
  public static func content(fromRecord record: TodoListItem) -> TodoItemModel {
    return TodoItemModel(item: record)
  }

  public typealias ContentType = TodoItemModel
}

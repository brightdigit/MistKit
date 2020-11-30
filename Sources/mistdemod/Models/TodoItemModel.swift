import MistKitDemo
import Vapor

struct TodoItemModel: Content {
  let id: UUID?
  let title: String
  init(item: TodoListItem) {
    title = item.title
    id = item.recordName
  }
}

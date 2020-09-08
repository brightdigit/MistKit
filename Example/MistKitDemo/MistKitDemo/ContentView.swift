import CloudKit
import SwiftUI

enum Errors: Error {
  case empty
}

struct TodoItem: Identifiable {
  public let id: UUID
  public let title: String
  public let completedDate: Date?

  init(record: CKRecord) throws {
    guard let id = UUID(uuidString: record.recordID.recordName) else {
      throw NSError()
    }

    guard let title = record["title"] as? String else {
      throw NSError()
    }

    self.id = id
    self.title = title
    completedDate = record["completedDate"] as? Date
  }
}

class MistObject: ObservableObject {
  @Published var items: Result<[TodoItem], Error>?
  let database: CKDatabase
  let container: CKContainer
  init() {
    let container = CKContainer(identifier: "iCloud.com.brightdigit.MistDemo")
    let database = container.privateCloudDatabase
    self.container = container
    self.database = database
    database.perform(.init(recordType: "TodoItem", predicate: .init(value: true)), inZoneWith: nil) { records, error in
      let result: Result<[TodoItem], Error>
      if let error = error {
        result = .failure(error)
      } else if let records = records {
        result = .init { try records.map(TodoItem.init) }
      } else {
        result = .failure(Errors.empty)
      }
      DispatchQueue.main.async {
        self.items = result
      }
    }
  }
}

struct ContentView: View {
  @EnvironmentObject var data: MistObject

  var error: Error? {
    switch data.items {
    case let .failure(error): return error
    default: return nil
    }
  }

  var isBusy: Bool {
    data.items == nil
  }

  var items: [TodoItem] {
    data.items.flatMap { try? $0.get() } ?? [TodoItem]()
  }

  var body: some View {
    NavigationView {
      ZStack {
        self.error.map { Text($0.localizedDescription) }
        Text("Loading").opacity(self.isBusy ? 1.0 : 0.0)
        List(self.items) { item in
          Text(item.title)
        }
      }.navigationTitle("Todo Items")
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

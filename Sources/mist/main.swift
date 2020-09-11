import Foundation
import MistKit
import MistKitNIOHTTP1Token

let apiKey = "c2b958e56ab5a41aa25d673f479bbac1379f1247d83199ccd94e38bb6ae715e2"
let container = "iCloud.com.brightdigit.MistDemo"

let dbConnection = MKDatabaseConnection(container: container, apiToken: apiKey, environment: .development)

let client = MKURLSessionClient(session: .shared)

let database = MKDatabase(
  connection: dbConnection,
  factory: MKURLBuilderFactory(),
  client: client,
  tokenManager: MKNIOHTTP1TokenManager()
)

var todoResult: Result<[TodoListItem], Error>?
func query(_ callback: @escaping ((Result<[TodoListItem], Error>) -> Void)) {
  let getTodosQuery = FetchRecordQueryRequest(database: .private, query: FetchRecordQuery(query: MKQuery(recordType: TodoListItem.self)))
  database.query(getTodosQuery) { result in
    let recordsResult: Result<[TodoListItem], Error>
    switch result {
    case let .success(result):
      recordsResult = .success(result)
    case let .failure(error):
      recordsResult = .failure(error)
    }
    callback(recordsResult)
  }
}

query { result in
  todoResult = result
}

while true {
  RunLoop.main.run(until: .distantPast)
  if let todoitems = todoResult {
    dump(todoitems)
    break
  }
}

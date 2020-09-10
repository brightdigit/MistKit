import Foundation
import MistKit
// import MistKitAuth

let apiKey = "c2b958e56ab5a41aa25d673f479bbac1379f1247d83199ccd94e38bb6ae715e2"
let container = "iCloud.com.brightdigit.MistDemo"

let dbConnection = MKDatabaseConnection(container: container, apiToken: apiKey, environment: .development)

let client = MKURLSessionClient(session: .shared)
let database = MKDatabase(
  connection: dbConnection,
  factory: MKURLBuilderFactory(),
  client: client,
  authenticationToken: nil
)

var recordsResult: MKResult<[TodoListItem], Error>?
let getTodosQuery = FetchRecordQueryRequest(database: .private, query: FetchRecordQuery(query: MKQuery(recordType: TodoListItem.self)))
database.query(getTodosQuery) { result in
  recordsResult = result
}

while true {
  RunLoop.main.run(until: .distantPast)
  if let todoitems = recordsResult {
    dump(todoitems)
    break
  }
}

// let channel = try startServer(
// htdocs: "",
// allowHalfClosure: true,
// bindTarget: .ip(host: "127.0.0.1", port: 7000))
//
//
// print(urlString)
// try channel.closeFuture.wait()

import Foundation
import MistKit
// import MistKitAuth

// swiftlint:disable:next all
let token = "29__54__AeRKh0by2d2DvN5Oz8PF4VAdx4UMoP1ZsmDwjCTRzmbgiyGp3xygO+MRZ9jjNuW/npq8rPnAjs/MHuGmTVfrbOy8Gzw00qK8CDiK9WbiX6wBoYEniyo75po5iC4fMq0sXoysth54wzokiQMsXDhqpotXUVJMlQVsuyImtZJOMLpgKLc+nr94e1VRBlrmuWdRtUN85Cch0RHij4xgorQkXOOQOmcujTsX88+61il9ugVahsVi19dKPhfE9B0lMZ7QByTk5IR3ZMEqeZVz7+nmitWJMn5/h82n8WIP2fx0FlXZ+gvwEt1AVRh314QG7VxAmCZipO0RrQx3mKxbUEX+QP2elNo4kY/F1rinLFbL04NXp+nKM0BDln8xN8D7SVrrwW1JiCqcJTAK2wh5gWpq3kbUV5Ti0nE8UzSX3X31tjoTtxk=__eyJYLUFQUExFLVdFQkFVVEgtUENTLUNsb3Vka2l0IjoiUVhCd2JEb3hPZ0dMK090eHFMeXlKSVJDeTdJai94aHBIN3puRStDS0g3WkMyVDNQWkorOGRvS2UrT24xdU9zMk94NUU0SjduSXJocDdrQXprZHNrQU9LYUVveWJVK0NFIiwiWC1BUFBMRS1XRUJBVVRILVBDUy1TaGFyaW5nIjoiUVhCd2JEb3hPZ0dYam54OVZHMEZxNkFWUndzRnViZCtpZ3RzUmJiMUtXOEs4bEhpWXE1UnRiZVZtczNkeW1CRzNac2xaYnZRM1V4b3grRjNyYlNmUkl2dUhqb2kvenBKIn0="

let apiKey = "c2b958e56ab5a41aa25d673f479bbac1379f1247d83199ccd94e38bb6ae715e2"
let container = "iCloud.com.brightdigit.MistDemo"

let dbConnection = MKDatabaseConnection(container: container, apiToken: apiKey, environment: .development)

let client = MKURLSessionClient(session: .shared)
let database = MKDatabase(
  connection: dbConnection,
  factory: MKURLBuilderFactory(),
  client: client,
  authenticationToken: token
)

var recordsResult: Result<[TodoListItem], Error>?
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

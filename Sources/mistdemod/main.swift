import MistKit
import MistKitVapor
import Vapor

import MistKitDemo

extension MKDatabase where HttpClient == MKURLSessionClient {
  init(options: MistDemoArguments, tokenManager: MKTokenManagerProtocol) {
    // setup your connection to CloudKit
    let connection = MKDatabaseConnection(container: options.container, apiToken: options.apiKey, environment: options.environment)

    // use the webAuthenticationToken which is passed
    if let token = options.token {
      tokenManager.webAuthenticationToken = token
    }

    self.init(
      connection: connection,
      tokenManager: tokenManager
    )
  }
}

struct MistDemoArguments {
  var apiKey = "eadc820055c358d8f261d561a93ac2c3ca962d3eca09d8b38c10c1e4beb05844"

  var container = "iCloud.com.brightdigit.MistDemo"

  var environment = MKEnvironment.development

  var token: String?
}

class MKVaporTokenClient: MKTokenClient {
  func request(_: MKAuthenticationResponse?, _ callback: @escaping (Result<String, Error>) -> Void) {
    callback(.failure(NSError()))
  }
}

let app = try Application(.detect())
defer { app.shutdown() }

struct TodoItemModel: Content {
  let id: UUID?
  let title: String
  init(item: TodoListItem) {
    title = item.title
    id = item.recordName
  }
}

let tokenClient = MKVaporTokenClient()

app.get("token") { (request) -> HTTPStatus in
  print(request)
  return HTTPStatus.accepted
  // https://localhost:8080/token?ckWebAuthToken=29__54__AYNnAxzqtf%2FkYdAk62NvEr%2BFjRQovNuI7YofL7OIuEdVnqSIElu8eHckOLKQMjxTm8MudlGy8itmpIbGGNee8y4Hx8pZ8MCGKb4ebMHXiDwcQslvfhodl7mdl8eUmAjXuxCTRuX2AVH6lwUDA9k9S1zDm%2FW1xH7c6HqAllbrgrnSy73%2B9F5Mj6QN30kuTAHfDwiBnVoS9yovFTGFVSSBLc85mqBp9lxzeOOXuMGHHjr6Eg8wPbHW8Sz5nbymBtF7wHEqyJK5Pr3to0xRoUggj7UGDiqLn0q0M1gp1OKpcNES2FaTGuUKqjS72sYfbQumNTXg2DrVLMKTsoQUcpHCCueStseYzEmkwZi4WVomCgriKQxHXB9dWZ0X9UNOHEZdf6W%2FCKERNHL9Svx4yho0bWcEpcmaKs13PV8ONf4vfbM4WNg%3D__eyJYLUFQUExFLVdFQkFVVEgtUENTLUNsb3Vka2l0IjoiUVhCd2JEb3hPZ0hwTmIvSzduc0JEcDBEV2Q0RlZ2dmhkYUZEdGtTTHpuYmN2bkNxRUNyWmJhNllFWTdEanhpbC9hQ0FRRUxKL01jQ0o3Z29tNmlEa2lLTjBJV0Y5Q2h6IiwiWC1BUFBMRS1XRUJBVVRILVBDUy1TaGFyaW5nIjoiUVhCd2JEb3hPZ0dDNGxKTkpPUXAremloSUdvRzRoQndoTXlvY2lSOENDOXMvMjVEbzhNUDY1Z3E4ZnF3UEdVWmdUQmE0bGR4Qm44Ukw5ZHRNNU11bU1CVm9KTXhDK2FaIn0%3D&ckSession=29__54__AYNnAxzqtf%2FkYdAk62NvEr%2BFjRQovNuI7YofL7OIuEdVnqSIElu8eHckOLKQMjxTm8MudlGy8itmpIbGGNee8y4Hx8pZ8MCGKb4ebMHXiDwcQslvfhodl7mdl8eUmAjXuxCTRuX2AVH6lwUDA9k9S1zDm%2FW1xH7c6HqAllbrgrnSy73%2B9F5Mj6QN30kuTAHfDwiBnVoS9yovFTGFVSSBLc85mqBp9lxzeOOXuMGHHjr6Eg8wPbHW8Sz5nbymBtF7wHEqyJK5Pr3to0xRoUggj7UGDiqLn0q0M1gp1OKpcNES2FaTGuUKqjS72sYfbQumNTXg2DrVLMKTsoQUcpHCCueStseYzEmkwZi4WVomCgriKQxHXB9dWZ0X9UNOHEZdf6W%2FCKERNHL9Svx4yho0bWcEpcmaKs13PV8ONf4vfbM4WNg%3D__eyJYLUFQUExFLVdFQkFVVEgtUENTLUNsb3Vka2l0IjoiUVhCd2JEb3hPZ0hwTmIvSzduc0JEcDBEV2Q0RlZ2dmhkYUZEdGtTTHpuYmN2bkNxRUNyWmJhNllFWTdEanhpbC9hQ0FRRUxKL01jQ0o3Z29tNmlEa2lLTjBJV0Y5Q2h6IiwiWC1BUFBMRS1XRUJBVVRILVBDUy1TaGFyaW5nIjoiUVhCd2JEb3hPZ0dDNGxKTkpPUXAremloSUdvRzRoQndoTXlvY2lSOENDOXMvMjVEbzhNUDY1Z3E4ZnF3UEdVWmdUQmE0bGR4Qm44Ukw5ZHRNNU11bU1CVm9KTXhDK2FaIn0%3D
}

app.get("list") { req -> EventLoopFuture<[TodoItemModel]> in
  // setup how to manager your user's web authentication token
  let manager = MKTokenManager(storage: MKUserDefaultsStorage(), client: tokenClient)

  // setup your database manager
  let database = MKDatabase(options: MistDemoArguments(), tokenManager: manager)

  // create your request to CloudKit
  let query = MKQuery(recordType: TodoListItem.self)

  let request = FetchRecordQueryRequest(
    database: .private,
    query: FetchRecordQuery(query: query)
  )

  let promise = req.eventLoop.makePromise(of: [TodoItemModel].self)
  // handle the result
  database.query(request) { result in
    let actual = result.map { $0.map(TodoItemModel.init) }
    promise.completeWith(actual)
//    do {
//      try print(result.get().information)
//    } catch {
//      //completed(error)
//      return
//    }
    // completed(nil)
  }
  return promise.futureResult
}

try app.run()

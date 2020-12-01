import MistKit
import MistKitDemo
import MistKitVapor
import Vapor

extension MKDatabase where HttpClient == MKVaporClient {
  init(request: Request) {
    let storage: MKTokenStorage
    if let user = request.auth.get(User.self) {
      storage = MKVaporModelStorage(model: user)
    } else {
      storage = request.cloudKitAPI
    }
    let manager = MKTokenManager(storage: storage, client: nil)

    let options = MistDemoDefaultConfiguration(apiKey: request.application.cloudKitAPIKey)
    let connection = MKDatabaseConnection(container: options.container, apiToken: options.apiKey, environment: options.environment)

    // use the webAuthenticationToken which is passed
    if let token = options.token {
      manager.webAuthenticationToken = token
    }

    self.init(connection: connection, factory: nil, client: MKVaporClient(client: request.client), tokenManager: manager)
  }
}

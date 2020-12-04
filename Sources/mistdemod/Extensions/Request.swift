import MistKit
import MistKitVapor
import Vapor

extension Request {
  var cloudKitAPI: MKTokenStorage {
    MKVaporSessionStorage(session: session)
  }
}

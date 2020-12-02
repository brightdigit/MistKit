import MistKit
import MistKitVapor
import Vapor

extension Request {
  var cloudKitAPI: MKTokenStorage {
    return MKVaporSessionStorage(session: session)
  }
}

import MistKit
import MistKitVapor
import Vapor

public extension Request {
  var cloudKitAPI: MKTokenStorage {
    MKVaporSessionStorage(session: session)
  }
}

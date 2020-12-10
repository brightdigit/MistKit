import MistKit
import Vapor

public class MKVaporSessionStorage: MKTokenStorage {
  public let session: Session
  public let name: String

  public var webAuthenticationToken: String? {
    get {
      session.data[name]
    }
    set {
      session.data[name] = newValue
    }
  }

  public init(session: Session, name: String = "ckWebAuthToken") {
    self.session = session
    self.name = name
  }
}

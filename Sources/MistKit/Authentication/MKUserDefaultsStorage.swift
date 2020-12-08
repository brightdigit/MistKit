import Foundation

public class MKUserDefaultsStorage: MKTokenStorage {
  public let userDefaults: UserDefaults

  public init(userDefaults: UserDefaults? = nil) {
    self.userDefaults = userDefaults ?? .standard
  }

  public var webAuthenticationToken: String? {
    get {
      userDefaults.string(forKey: "webAuthenticationToken")
    }
    set {
      userDefaults.set(newValue, forKey: "webAuthenticationToken")
    }
  }
}

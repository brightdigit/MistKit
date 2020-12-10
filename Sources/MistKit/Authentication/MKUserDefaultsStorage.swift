import Foundation

public class MKUserDefaultsStorage: MKTokenStorage {
  public let userDefaults: UserDefaults

  public var webAuthenticationToken: String? {
    get {
      userDefaults.string(forKey: "webAuthenticationToken")
    }
    set {
      userDefaults.set(newValue, forKey: "webAuthenticationToken")
    }
  }

  public init(userDefaults: UserDefaults? = nil) {
    self.userDefaults = userDefaults ?? .standard
  }
}

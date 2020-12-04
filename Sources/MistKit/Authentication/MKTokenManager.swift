public class MKTokenManager: MKTokenManagerProtocol {
  public init(storage: MKTokenStorage, client: MKTokenClient?) {
    self.storage = storage
    self.client = client
  }

  public let storage: MKTokenStorage
  public let client: MKTokenClient?

  public var webAuthenticationToken: String? {
    get {
      storage.webAuthenticationToken
    }
    set {
      storage.webAuthenticationToken = newValue
    }
  }

  public func request(_ request: MKAuthenticationResponse, _ callback: @escaping (Result<String, Error>) -> Void) {
    guard let client = self.client else {
      callback(.failure(MKError.authenticationRequired(request)))
      return
    }
    client.request(request) {
      if let token = try? $0.get() {
        self.webAuthenticationToken = token
      }
      callback($0)
    }
  }
}

public class MKTokenManager: MKWritableTokenManagerProtocol {
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

  public init(storage: MKTokenStorage, client: MKTokenClient?) {
    self.storage = storage
    self.client = client
  }

  public func request(
    _ request: MKAuthenticationRedirect,
    _ callback: @escaping (Result<String, Error>) -> Void
  ) {
    guard let client = client else {
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

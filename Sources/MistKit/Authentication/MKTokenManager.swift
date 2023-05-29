public class MKTokenManager: MKWritableTokenManagerProtocol {
  public let storage: any MKTokenStorage
  public let client: (any MKTokenClient)?

  public var webAuthenticationToken: String? {
    get {
      storage.webAuthenticationToken
    }
    set {
      storage.webAuthenticationToken = newValue
    }
  }

  public init(storage: any MKTokenStorage, client: (any MKTokenClient)?) {
    self.storage = storage
    self.client = client
  }

  public func request(
    _ request: any MKAuthenticationRedirect,
    _ callback: @escaping (Result<String, Error>) -> Void
  ) {
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

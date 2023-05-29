public class MKStaticTokenManager: MKTokenManagerProtocol {
  public let token: String?
  public let client: (any MKTokenClient)?

  public var webAuthenticationToken: String? {
    token
  }

  public init(token: String?, client: (any MKTokenClient)?) {
    self.token = token
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
      callback($0)
    }
  }
}

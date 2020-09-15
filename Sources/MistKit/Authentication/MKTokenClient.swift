public protocol MKTokenClient: AnyObject {
  func request(_ request: MKAuthenticationResponse?, _ callback: @escaping (Result<String, Error>) -> Void)
}

public protocol MKTokenClient: AnyObject {
  func request(
    _ request: (any MKAuthenticationRedirect)?,
    _ callback: @escaping (Result<String, Error>) -> Void
  )
}

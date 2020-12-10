public protocol MKTokenClient: AnyObject {
  func request(
    _ request: MKAuthenticationRedirect?,
    _ callback: @escaping (Result<String, Error>) -> Void
  )
}

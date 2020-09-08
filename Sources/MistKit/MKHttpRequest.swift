public protocol MKHttpRequest {
  func execute(_ callback: @escaping ((Result<MKHttpResponse, Error>) -> Void))
}

public protocol MKHttpRequest {
  func execute(_ callback: @escaping ((Result<any MKHttpResponse, Error>) -> Void))
}

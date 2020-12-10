public protocol ResultSinkProtocol {
  func database<RequestType: MKRequest, ResponseType, HttpClientType: MKHttpClient>(
    _ database: MKDatabase<HttpClientType>,
    request: RequestType,
    completedWith result: Result<MKHttpResponse, Error>,
    shouldFailAuth: Bool,
    _ callback: @escaping ((Result<ResponseType, Error>) -> Void)
  ) where RequestType.Response == ResponseType
}

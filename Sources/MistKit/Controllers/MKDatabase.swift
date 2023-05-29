import Foundation

public struct MKDatabase<HttpClient: MKHttpClient> {
  public let urlBuilder: any MKURLBuilderProtocol
  public let requestConfigFactory: any RequestConfigurationFactoryProtocol
  public let client: HttpClient
  public let resultSink: any ResultSinkProtocol

  public init(connection: MKDatabaseConnection,
              client: HttpClient,
              factory: MKURLBuilderFactory? = nil,
              requestConfigFactory: (any RequestConfigurationFactoryProtocol)? = nil,
              resultSink: (any ResultSinkProtocol)? = nil,
              tokenManager: (any MKTokenManagerProtocol)? = nil) {
    let factory = factory ?? MKURLBuilderFactory()
    urlBuilder = factory.builder(
      forConnection: connection,
      withTokenManager: tokenManager
    )
    self.requestConfigFactory = requestConfigFactory ?? RequestConfigurationFactory()
    self.client = client
    self.resultSink = resultSink ?? ResultSink()
  }

  public func perform<RequestType: MKRequest, ResponseType>(
    request: RequestType,
    returnFailedAuthentication: Bool = false,
    _ callback: @escaping ((Result<ResponseType, Error>) -> Void)
  ) where RequestType.Response == ResponseType {
    let requestConfig: RequestConfiguration
    do {
      requestConfig = try requestConfigFactory.configuration(
        from: request,
        withURLBuilder: urlBuilder
      )
    } catch {
      callback(.failure(error))
      return
    }
    let httpRequest = client.request(fromConfiguration: requestConfig)
    httpRequest.execute { result in
      self.resultSink.database(
        self,
        request: request,
        completedWith: result,
        shouldFailAuth: returnFailedAuthentication,
        callback
      )
    }
  }
}

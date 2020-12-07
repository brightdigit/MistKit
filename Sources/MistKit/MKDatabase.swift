import Foundation

public struct RequestConfiguration {
  public let url: URL
  public let data: Data?
}

public protocol RequestConfigurationFactoryProtocol {
  func configuration<RequestType: MKRequest>(from request: RequestType, withURLBuilder urlBuilder: MKURLBuilder) throws -> RequestConfiguration
}

public struct RequestConfigurationFactory: RequestConfigurationFactoryProtocol {
  let encoder: MKEncoder = JSONEncoder()

  public func configuration<RequestType>(
    from request: RequestType,
    withURLBuilder urlBuilder: MKURLBuilder
  ) throws -> RequestConfiguration where RequestType: MKRequest {
    let url: URL = try urlBuilder.url(withPathComponents: request.relativePath)
    let data: Data? = try encoder.optionalData(from: request.data)
    return RequestConfiguration(url: url, data: data)
  }
}

public protocol ResultTransformerProtocol {
  func data(fromResult result: Result<MKHttpResponse, Error>, setWebAuthenticationToken: (String) -> Void) -> Result<Data, Error>
}

public struct MKDatabase<HttpClient: MKHttpClient> {
  let urlBuilder: MKURLBuilder
  let requestConfigFactory: RequestConfigurationFactoryProtocol
  let decoder: MKDecoder = JSONDecoder()
  let client: HttpClient

  public init(connection: MKDatabaseConnection,
              factory: MKURLBuilderFactory? = nil,
              requestConfigFactory _: RequestConfigurationFactoryProtocol? = nil,
              client: HttpClient,
              tokenManager: MKTokenManagerProtocol? = nil) {
    let factory = factory ?? MKURLBuilderFactory()
    urlBuilder = factory.builder(forConnection: connection, withTokenManager: tokenManager)
    requestConfigFactory = RequestConfigurationFactory()
    self.client = client
  }

  private static func data(fromResult result: Result<MKHttpResponse, Error>, setWebAuthenticationToken: (String) -> Void) -> Result<Data, Error> {
    result.flatMap { response -> Result<Data, Error> in
      if let webAuthenticationToken = response.webAuthenticationToken {
        setWebAuthenticationToken(webAuthenticationToken)
      }
      guard let data = response.body else {
        return .failure(MKError.noDataFromStatus(response.status))
      }
      return .success(data)
    }
  }

  private static func onResult<RequestType: MKRequest, ResponseType>(
    _ result: Result<MKHttpResponse, Error>,
    fromRequest request: RequestType,
    decoder: MKDecoder,
    onFailedAuthentication: MKDatabase?,
    setWebAuthenticationToken: (String) -> Void,
    _ callback: @escaping ((Result<ResponseType, Error>) -> Void)
  )
    where RequestType.Response == ResponseType {
    let dataResult = Self.data(fromResult: result, setWebAuthenticationToken: setWebAuthenticationToken)
    let newResult: Result<ResponseType, Error>
    switch dataResult {
    case let .success(data):
      do {
        let value = try decoder.decode(RequestType.Response.self, from: data)
        newResult = .success(value)
        break
      } catch {
        do {
          let auth = try decoder.decode(MKAuthenticationResponse.self, from: data)

          if let onFailedAuthentication = onFailedAuthentication, let tokenManager = onFailedAuthentication.urlBuilder.tokenManager {
            tokenManager.request(auth) { _ in
              onFailedAuthentication.perform(request: request, returnFailedAuthentication: true, callback)
            }
            return
          } else {
            newResult = .failure(MKError.authenticationRequired(auth))
          }
        } catch {
          newResult = .failure(error)
        }
      }

    case let .failure(error):
      newResult = .failure(error)
    }
    callback(newResult)
  }

  public func perform<RequestType: MKRequest, ResponseType>(
    request: RequestType,
    returnFailedAuthentication _: Bool = false,
    _ callback: @escaping ((Result<ResponseType, Error>) -> Void)
  ) where RequestType.Response == ResponseType {
    let requestConfig: RequestConfiguration
    do {
      requestConfig = try requestConfigFactory.configuration(from: request, withURLBuilder: urlBuilder)
    } catch {
      callback(.failure(error))
      return
    }
    let httpRequest = client.request(fromConfiguration: requestConfig)
    httpRequest.execute { result in
      Self.onResult(
        result,
        fromRequest: request,
        decoder: self.decoder,
        onFailedAuthentication: nil,
        setWebAuthenticationToken: { self.urlBuilder.tokenManager?.webAuthenticationToken = $0 },
        callback
      )
    }
  }
}

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public extension MKDatabase where HttpClient == MKURLSessionClient {
  init(connection: MKDatabaseConnection,
       factory: MKURLBuilderFactory? = nil,
       requestConfigFactory _: RequestConfigurationFactoryProtocol? = nil,
       tokenManager: MKTokenManagerProtocol? = nil,
       session: URLSession? = nil) {
    let factory = factory ?? MKURLBuilderFactory()
    urlBuilder = factory.builder(forConnection: connection, withTokenManager: tokenManager)
    client = MKURLSessionClient(session: session ?? URLSession.shared)
    requestConfigFactory = RequestConfigurationFactory()
  }
}

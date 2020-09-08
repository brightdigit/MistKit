import Foundation

public struct MKDatabase<HttpClient: MKHttpClient> {
  let urlBuilder: MKURLBuilder
  let encoder: MKEncoder = JSONEncoder()
  let decoder: MKDecoder = JSONDecoder()
  let client: HttpClient

  public init(connection: MKDatabaseConnection, factory: MKURLBuilderFactory? = nil, client: HttpClient, authenticationToken: String? = nil) {
    let factory = factory ?? MKURLBuilderFactory()
    urlBuilder = factory.builder(forConnection: connection, withWebAuthToken: authenticationToken)
//      MKURLBuilder(tokenEncoder: CharacterMapEncoder(), connection: connection, webAuthenticationToken: authenticationToken)
    self.client = client
  }

  public func perform<RequestType: MKRequest, ResponseType>(
    request: RequestType,
    _ callback: @escaping ((Result<ResponseType, Error>) -> Void)
  ) where RequestType.Response == ResponseType {
    let url: URL
    let data: Data?
    do {
      url = try urlBuilder.url(withPathComponents: request.relativePath)
      data = try encoder.optionalData(from: request.data)
    } catch {
      callback(.failure(error))
      return
    }
    let httpRequest = client.request(withURL: url, data: data)
    httpRequest.execute { result in

      let newResult = result.flatMap { (response) -> Result<Data, Error> in
        if let webAuthenticationToken = response.webAuthenticationToken {
          self.urlBuilder.webAuthenticationToken = webAuthenticationToken
        }
        guard let data = response.body else {
          return .failure(MKError.noDataFromStatus(response.status))
        }
        return .success(data)
      }.flatMap { data in
        Result {
          try self.decoder.decode(RequestType.Response.self, from: data)
        }
      }
      callback(newResult)
    }
  }
}

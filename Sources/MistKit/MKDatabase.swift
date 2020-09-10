import Foundation

public protocol MKAuthRedirect {
  var url: URL { get }
}

public enum MKResult<Success, Failure: Error> {
  case success(Success)
  case authenticationRequired(MKAuthRedirect)
  case failure(Failure)
}

public struct MKDatabase<HttpClient: MKHttpClient> {
  let urlBuilder: MKURLBuilder
  let encoder: MKEncoder = JSONEncoder()
  let decoder: MKDecoder = JSONDecoder()
  let client: HttpClient

  public var webAuthenticationToken: String? {
    get {
      return urlBuilder.webAuthenticationToken
    }
    set {
      urlBuilder.webAuthenticationToken = newValue
    }
  }

  public init(connection: MKDatabaseConnection, factory: MKURLBuilderFactory? = nil, client: HttpClient, authenticationToken: String? = nil) {
    let factory = factory ?? MKURLBuilderFactory()
    urlBuilder = factory.builder(forConnection: connection, withWebAuthToken: authenticationToken)
//      MKURLBuilder(tokenEncoder: CharacterMapEncoder(), connection: connection, webAuthenticationToken: authenticationToken)
    self.client = client
  }

  public func perform<RequestType: MKRequest, ResponseType>(
    request: RequestType,
    _ callback: @escaping ((MKResult<ResponseType, Error>) -> Void)
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

      let dataResult = result.flatMap { (response) -> Result<Data, Error> in
        if let webAuthenticationToken = response.webAuthenticationToken {
          self.urlBuilder.webAuthenticationToken = webAuthenticationToken
        }
        guard let data = response.body else {
          return .failure(MKError.noDataFromStatus(response.status))
        }
        return .success(data)
      }
      let newResult: MKResult<ResponseType, Error>
      switch dataResult {
      case let .success(data):
        do {
          let value = try self.decoder.decode(RequestType.Response.self, from: data)
          newResult = .success(value)
          break
        } catch {
          do {
            let auth = try self.decoder.decode(MKErrorResponse.self, from: data)
            newResult = .authenticationRequired(auth)
          } catch {
            newResult = .failure(error)
          }
        }
      case let .failure(error):
        newResult = .failure(error)
      }
//      .flatMap { data in
//        Result {
//
//        }
//      }
      callback(newResult)
    }
  }
}

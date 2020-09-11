import Foundation
//
// @available(*, deprecated)
// public enum MKResult<Success, Failure: Error> {
//  case success(Success)
//  case authenticationRequired(MKAuthenticationRedirect)
//  case failure(Failure)
// }

public struct MKDatabase<HttpClient: MKHttpClient> {
  let urlBuilder: MKURLBuilder
  let encoder: MKEncoder = JSONEncoder()
  let decoder: MKDecoder = JSONDecoder()
  let client: HttpClient

  public nonmutating func setWebAuthenticationToken(_ newValue: String) {
    urlBuilder.tokenManager?.webAuthenticationToken = newValue
  }

  public init(connection: MKDatabaseConnection, factory: MKURLBuilderFactory? = nil, client: HttpClient, tokenManager: MKTokenManager? = nil) {
    let factory = factory ?? MKURLBuilderFactory()
    urlBuilder = factory.builder(forConnection: connection, withTokenManager: tokenManager)
    self.client = client
  }

  public func perform<RequestType: MKRequest, ResponseType>(
    request: RequestType,
    returnFailedAuthentication: Bool = false,
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

      let dataResult = result.flatMap { (response) -> Result<Data, Error> in
        if let webAuthenticationToken = response.webAuthenticationToken {
          self.urlBuilder.tokenManager?.webAuthenticationToken = webAuthenticationToken
        }
        guard let data = response.body else {
          return .failure(MKError.noDataFromStatus(response.status))
        }
        return .success(data)
      }
      let newResult: Result<ResponseType, Error>
      switch dataResult {
      case let .success(data):
        do {
          let value = try self.decoder.decode(RequestType.Response.self, from: data)
          newResult = .success(value)
          break
        } catch {
          do {
            let auth = try self.decoder.decode(MKAuthenticationResponse.self, from: data)

            if let tokenManager = self.urlBuilder.tokenManager, !returnFailedAuthentication {
              tokenManager.request(auth) { _ in
                self.perform(request: request, returnFailedAuthentication: true, callback)
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
  }
}

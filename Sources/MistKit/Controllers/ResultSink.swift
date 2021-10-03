import Foundation

public struct ResultSink: ResultSinkProtocol {
  public let dataTransformer: ResultTransformerProtocol
  public let decoder: MKDecoder

  public init(
    dataTransformer: ResultTransformerProtocol? = nil,
    decoder: MKDecoder? = nil
  ) {
    self.dataTransformer = dataTransformer ?? ResultTransformer()
    self.decoder = decoder ?? JSONDecoder()
  }

  public func response<RequestType, ResponseType>(
    fromResult dataResult: Result<Data, Error>,
    ofRequest _: RequestType,
    shouldFailAuth _: Bool
  ) -> Result<ResponseType, Error>
    where RequestType: MKRequest, ResponseType == RequestType.Response {
    dataResult.flatMap { data in
      Result {
        do {
          return try decoder.decode(RequestType.Response.self, from: data)
        } catch {
          let auth = try decoder.decode(
            MKAuthenticationResponse.self,
            from: data
          )

          throw MKError.authenticationRequired(auth)
        }
      }
    }
  }

  public func database<RequestType, ResponseType, HttpClientType>(
    _ database: MKDatabase<HttpClientType>,
    request: RequestType,
    completedWith result: Result<MKHttpResponse, Error>,
    shouldFailAuth: Bool,
    _ callback: @escaping ((Result<ResponseType, Error>) -> Void)
  ) where RequestType: MKRequest,
    ResponseType == RequestType.Response,
    HttpClientType: MKHttpClient {
    let setWebAuthenticationToken: ((String) -> Void)?

    if let writable =
      database.urlBuilder.tokenManager as? MKWritableTokenManagerProtocol {
      setWebAuthenticationToken = { writable.webAuthenticationToken = $0 }
    } else {
      setWebAuthenticationToken = nil
    }

    let dataResult = dataTransformer.data(
      fromResult: result,
      setWebAuthenticationToken: setWebAuthenticationToken
    )
    let newResult = response(
      fromResult: dataResult,
      ofRequest: request,
      shouldFailAuth: shouldFailAuth
    )

    if !shouldFailAuth,
       let tokenManager = database.urlBuilder.tokenManager,
       let redirect = newResult.authResponse {
      tokenManager.request(redirect) { _ in
        database.perform(
          request: request,
          returnFailedAuthentication: true,
          callback
        )
      }
      return
    }

    callback(newResult)
  }
}

public extension Result {
  var authResponse: MKAuthenticationRedirect? {
    guard case let .failure(error) = self else {
      return nil
    }

    guard let mkError = error as? MKError else {
      return nil
    }

    guard case let .authenticationRequired(auth) = mkError else {
      return nil
    }

    return auth
  }
}

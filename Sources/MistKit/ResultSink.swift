import Foundation

public struct ResultSink: ResultSinkProtocol {
  public init(dataTransformer: ResultTransformerProtocol? = nil, decoder: MKDecoder? = nil) {
    self.dataTransformer = dataTransformer ?? ResultTransformer()
    self.decoder = decoder ?? JSONDecoder()
  }

  public let dataTransformer: ResultTransformerProtocol
  public let decoder: MKDecoder

  public func response<RequestType, ResponseType>(
    fromResult dataResult: Result<Data, Error>,
    ofRequest _: RequestType,

    shouldFailAuth _: Bool
  ) -> Result<ResponseType, Error> where RequestType: MKRequest, ResponseType == RequestType.Response {
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

          newResult = .failure(MKError.authenticationRequired(auth))
        } catch {
          newResult = .failure(error)
        }
      }

    case let .failure(error):
      newResult = .failure(error)
    }
    return newResult
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
    let dataResult = dataTransformer.data(
      fromResult: result,
      setWebAuthenticationToken: {
        database.urlBuilder.tokenManager?.webAuthenticationToken = $0
      }
    )
    let newResult = response(
      fromResult: dataResult,
      ofRequest: request,
      shouldFailAuth: shouldFailAuth
    )

    if !shouldFailAuth, let tokenManager = database.urlBuilder.tokenManager, let redirect = newResult.authResponse {
      // database.perform(request: request, returnFailedAuthentication: shouldFailAuth, callback)
      tokenManager.request(redirect) { _ in
        database.perform(request: request, returnFailedAuthentication: true, callback)
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

import Foundation

public struct ResultTransformer: ResultTransformerProtocol {
  public func data(
    fromResult result: Result<MKHttpResponse, Error>,
    setWebAuthenticationToken: ((String) -> Void)?
  ) -> Result<Data, Error> {
    result.flatMap { response -> Result<Data, Error> in
      if let webAuthenticationToken = response.webAuthenticationToken,
         let setWebAuthenticationToken = setWebAuthenticationToken {
        setWebAuthenticationToken(webAuthenticationToken)
      }
      guard let data = response.body else {
        return .failure(MKError.noDataFromStatus(response.status))
      }
      return .success(data)
    }
  }
}

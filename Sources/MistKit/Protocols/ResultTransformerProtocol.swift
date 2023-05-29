import Foundation

public protocol ResultTransformerProtocol {
  func data(
    fromResult result: Result<any MKHttpResponse, Error>,
    setWebAuthenticationToken: ((String) -> Void)?
  ) -> Result<Data, Error>
}

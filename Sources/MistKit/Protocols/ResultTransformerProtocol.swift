import Foundation

public protocol ResultTransformerProtocol {
  func data(
    fromResult result: Result<MKHttpResponse, Error>,
    setWebAuthenticationToken: (String) -> Void
  ) -> Result<Data, Error>
}

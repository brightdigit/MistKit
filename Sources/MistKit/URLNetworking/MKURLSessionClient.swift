import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public struct MKURLSessionClient: MKHttpClient {
  public typealias RequestType = MKURLRequest

  public let session: URLSession

  public init(session: URLSession) {
    self.session = session
  }

  public func request(
    fromConfiguration configuration: RequestConfiguration
  ) -> MKURLRequest {
    var urlRequest = URLRequest(url: configuration.url)
    if let data = configuration.data {
      urlRequest.httpBody = data
      urlRequest.httpMethod = "POST"
      urlRequest.allHTTPHeaderFields = ["Content-Type": "application/json"]
    }
    return MKURLRequest(urlRequest: urlRequest, urlSession: session)
  }
}

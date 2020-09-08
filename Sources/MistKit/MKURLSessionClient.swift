import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public struct MKURLSessionClient: MKHttpClient {
  public init(session: URLSession) {
    self.session = session
  }

  public let session: URLSession
  public func request(withURL url: URL, data: Data?) -> MKURLRequest {
    var urlRequest = URLRequest(url: url)
    if let data = data {
      urlRequest.httpBody = data
      urlRequest.httpMethod = "POST"
      urlRequest.allHTTPHeaderFields = ["Content-Type": "application/json"]
    }
    return MKURLRequest(urlRequest: urlRequest, urlSession: session)
  }

  public typealias RequestType = MKURLRequest
}

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

  public func request(withURL url: URL, data: Data?) -> MKURLRequest {
    var urlRequest = URLRequest(url: url)
    if let data = data {
      #if DEBUG
        if let text = String(data: data, encoding: .utf8) {
          debugPrint(text)
        }
      #endif
      urlRequest.httpBody = data
      urlRequest.httpMethod = "POST"
      urlRequest.allHTTPHeaderFields = ["Content-Type": "application/json"]
    }
    return MKURLRequest(urlRequest: urlRequest, urlSession: session)
  }
}

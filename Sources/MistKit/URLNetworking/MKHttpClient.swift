import Foundation

public protocol MKHttpClient {
  associatedtype RequestType: MKHttpRequest
  @available(*, renamed: "request")
  func request(withURL url: URL, data: Data?) -> RequestType
}

public extension MKHttpClient {
  func request(fromConfiguration configuration: RequestConfiguration) -> RequestType {
    return request(withURL: configuration.url, data: configuration.data)
  }
}

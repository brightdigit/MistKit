import Foundation

public protocol MKHttpClient {
  associatedtype RequestType: MKHttpRequest
  func request(withURL url: URL, data: Data?) -> RequestType
}

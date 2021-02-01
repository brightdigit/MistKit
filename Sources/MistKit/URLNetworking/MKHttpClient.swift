import Foundation

public protocol MKHttpClient {
  associatedtype RequestType: MKHttpRequest
  func request(fromConfiguration configuration: RequestConfiguration) -> RequestType
}

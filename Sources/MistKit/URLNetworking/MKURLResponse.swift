import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public struct MKURLResponse: MKHttpResponse {
  public let body: Data?
  public let response: HTTPURLResponse

  public var status: Int {
    response.statusCode
  }

  public var webAuthenticationToken: String? {
    response.allHeaderFields["X-Apple-CloudKit-Web-Auth-Token"] as? String
  }
}

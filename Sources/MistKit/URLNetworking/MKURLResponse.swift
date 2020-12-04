import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct MKURLResponse: MKHttpResponse {
  let body: Data?
  let response: HTTPURLResponse

  var status: Int {
    response.statusCode
  }

  var webAuthenticationToken: String? {
    response.allHeaderFields["X-Apple-CloudKit-Web-Auth-Token"] as? String
  }
}

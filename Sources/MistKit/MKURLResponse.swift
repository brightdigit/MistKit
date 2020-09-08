import Foundation

struct MKURLResponse: MKHttpResponse {
  let body: Data?
  let response: HTTPURLResponse

  var status: Int {
    return response.statusCode
  }

  var webAuthenticationToken: String? {
    response.allHeaderFields["X-Apple-CloudKit-Web-Auth-Token"] as? String
  }
}

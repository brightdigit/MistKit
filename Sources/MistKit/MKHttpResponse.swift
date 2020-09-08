import Foundation

public protocol MKHttpResponse {
  var body: Data? { get }
  var status: Int { get }
  var webAuthenticationToken: String? { get }
}

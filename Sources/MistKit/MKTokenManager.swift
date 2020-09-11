import Foundation

public protocol MKTokenManager: AnyObject {
  var webAuthenticationToken: String? { get set }

  func request(_ request: MKErrorResponse?, _ callback: @escaping (Result<String, Error>) -> Void)
}

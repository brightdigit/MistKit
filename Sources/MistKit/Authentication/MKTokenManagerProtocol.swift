import Foundation

public protocol MKTokenManagerProtocol: AnyObject {
  var webAuthenticationToken: String? { get set }

  func request(_ request: MKAuthenticationRedirect, _ callback: @escaping (Result<String, Error>) -> Void)
}

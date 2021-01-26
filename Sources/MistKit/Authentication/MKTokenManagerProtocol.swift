import Foundation



public protocol MKTokenManagerProtocol: AnyObject {
  var webAuthenticationToken: String? { get }

  func request(
    _ request: MKAuthenticationRedirect,
    _ callback: @escaping (Result<String, Error>) -> Void
  )
}

public protocol MKWritableTokenManagerProtocol : MKTokenManagerProtocol {
  var webAuthenticationToken: String? { get set }
  
}

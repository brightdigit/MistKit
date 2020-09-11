import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public protocol MKAuthenticationRedirect {
  var url: URL { get }
}

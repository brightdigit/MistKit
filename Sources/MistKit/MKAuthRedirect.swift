import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public protocol MKAuthRedirect {
  var url: URL { get }
}

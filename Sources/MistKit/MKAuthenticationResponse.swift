import Foundation

public struct MKAuthenticationResponse: MKDecodable {
  public let uuid: UUID
  public let serverErrorCode: MKErrorCode
  public let reason: String
  public let redirectURL: URL
}

extension MKAuthenticationResponse: MKAuthenticationRedirect {
  public var url: URL {
    return redirectURL
  }
}

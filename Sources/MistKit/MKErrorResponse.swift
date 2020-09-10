import Foundation

public struct MKErrorResponse: MKDecodable {
  public let uuid: UUID
  public let serverErrorCode: MKErrorCode
  public let reason: String
  public let redirectURL: URL
}

extension MKErrorResponse: MKAuthRedirect {
  public var url: URL {
    return redirectURL
  }
}

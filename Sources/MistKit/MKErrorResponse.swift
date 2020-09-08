import Foundation

public struct MKErrorResponse: Codable {
  public let uuid: UUID
  public let serverErrorCode: MKErrorCode
  public let reason: String
  public let redirectURL: URL
}

import Foundation

public struct LookupRecord: MKEncodable {
  public let recordName: UUID
  public let desiredKeys: [String]? = nil
}

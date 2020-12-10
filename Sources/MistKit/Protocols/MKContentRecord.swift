public protocol MKContentRecord: MKQueryRecord {
  associatedtype ContentType: Codable

  static func content(fromRecord record: Self) -> ContentType
}

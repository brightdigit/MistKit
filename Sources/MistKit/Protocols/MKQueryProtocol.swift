public protocol MKQueryProtocol: Encodable {
  var recordType: String { get }
  var desiredKeys: [String]? { get }
}

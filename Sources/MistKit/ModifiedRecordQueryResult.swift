public struct ModifyRecordQuery<RecordType: MKQueryRecord>: MKEncodable {
  public init(operations: [ModifyOperation<RecordType>]) {
    self.operations = operations
  }

  public let operations: [ModifyOperation<RecordType>]
  // public let atomic = true
  public let desiredKeys: [String]? = nil
  public let numbersAsStrings: Bool = true
}

public struct ModifyRecordQuery<RecordType: MKQueryRecord>: MKEncodable {
  public let operations: [ModifyOperation<RecordType>]
  // public let atomic = true
  public let desiredKeys: [String]? = nil
  public let numbersAsStrings = true

  public init(operations: [ModifyOperation<RecordType>]) {
    self.operations = operations
  }
}

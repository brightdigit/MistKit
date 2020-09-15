public struct ModifyOperation<RecordType: MKQueryRecord>: Encodable {
  public init(operationType: ModifyOperationType, record: RecordType, desiredKeys: [String]? = nil) {
    self.operationType = operationType
    self.record = MKAnyRecord(record: record)
    self.desiredKeys = desiredKeys
  }

  // The type of operation
  public let operationType: ModifyOperationType
  public let record: MKAnyRecord
  public let desiredKeys: [String]?
}

import Foundation

public struct FetchRecordQuery<QueryType: MKQueryProtocol>: MKEncodable {
  public let query: QueryType
  public let desiredKeys: [String]?
  public let numbersAsStrings: Bool = true

  public init(query: QueryType) {
    self.query = query
    desiredKeys = query.desiredKeys
  }
}

public enum ModifyOperationType: String, Encodable {
  // Create a new record. This operation fails if a record with the same record name already exists.
  case create
  // Update an existing record. Only the fields you specify are changed.
  case update
  // Update an existing record regardless of conflicts. Creates a record if it doesn’t exist.
  case forceUpdate
  // Replace a record with the specified record. The fields whose values you do not specify are set to null.
  case replace
  // Replace a record with the specified record regardless of conflicts. Creates a record if it doesn’t exist.
  case forceReplace
  // Delete the specified record.
  case delete
  // Delete the specified record regardless of conflicts.
  case forceDelete
}

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

public struct ModifyRecordQuery<RecordType: MKQueryRecord>: MKEncodable {
  public init(operations: [ModifyOperation<RecordType>]) {
    self.operations = operations
  }

  public let operations: [ModifyOperation<RecordType>]
  // public let atomic = true
  public let desiredKeys: [String]? = nil
  public let numbersAsStrings: Bool = true
}

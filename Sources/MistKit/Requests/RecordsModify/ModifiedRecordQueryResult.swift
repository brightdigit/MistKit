import Foundation
public struct ModifiedRecordQueryResult<RecordType: MKQueryRecord> {
  public let deleted: [UUID]
  public let updated: [RecordType]
}

public extension MKDatabase {
  func query<RecordType: MKQueryRecord>(
    _ query: FetchRecordQueryRequest<MKQuery<RecordType>>,
    _ callback: @escaping ((Result<[RecordType], Error>) -> Void)
  ) {
    perform(request: query) {
      callback($0.tryFlatmap(recordsTo: RecordType.self))
    }
  }

  fileprivate func resultFrom<RecordType: MKQueryRecord>(response: ModifyRecordQueryRequest<RecordType>.Response) -> Result<ModifiedRecordQueryResult<RecordType>, Error> {
    var updated = [RecordType]()
    var deleted = [UUID]()
    for record in response.records {
      switch record {
      case let .deleted(recordName):
        deleted.append(recordName)
        
      case let .updated(record):
        do {
          try updated.append(RecordType(record: record))
        } catch {
          return .failure(error)
        }
      }
    }
    return .success(.init(deleted: deleted, updated: updated))
  }
  
  func perform<RecordType: MKQueryRecord>(
    operations: ModifyRecordQueryRequest<RecordType>,
    _ callback: @escaping ((Result<ModifiedRecordQueryResult<RecordType>, Error>) -> Void)
  ) {
    perform(request: operations) { response in
      callback(response.flatMap(self.resultFrom(response:)))
    }
  }

  func lookup<RecordType: MKQueryRecord>(
    _ lookup: LookupRecordQueryRequest<RecordType>,
    _ callback: @escaping ((Result<[RecordType], Error>) -> Void)
  ) {
    perform(request: lookup) {
      callback($0.tryFlatmap(recordsTo: RecordType.self))
    }
  }
}

public extension Result {
  func tryFlatmap<RecordType: MKQueryRecord>(
    recordsTo _: RecordType.Type
  ) -> Result<[RecordType], Failure>
    where Success == FetchRecordQueryResponse, Failure == Error {
    flatMap { response in
      Result<[RecordType], Failure> {
        try response.records.map(RecordType.init(record:))
      }
    }
  }
}

extension MKDatabase {
  public func query<RecordType: MKQueryRecord>(
    _ query: FetchRecordQueryRequest<MKQuery<RecordType>>,
    _ callback: @escaping ((Result<[RecordType], Error>) -> Void)
  ) {
    perform(request: query) {
      callback($0.tryFlatmap(recordsTo: RecordType.self))
    }
  }
}

extension Result {
  func tryFlatmap<RecordType: MKQueryRecord>(
    recordsTo _: RecordType.Type
  ) -> Result<[RecordType], Failure>
    where Success == FetchRecordQueryResponse, Failure == Error {
    return flatMap { response in
      Result<[RecordType], Failure> {
        try response.records.map(RecordType.init(record:))
      }
    }
  }
}

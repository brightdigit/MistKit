extension MKDatabase {
  public func query<RecordType: MKQueryRecord>(_ query: FetchRecordQueryRequest<MKQuery<RecordType>>, _ callback: @escaping ((Result<[RecordType], Error>) -> Void)) {
    perform(request: query) { result in
      let newResult = result.flatMap { (response) -> Result<[RecordType], Error> in
        Result {
          try response.records.map(
            RecordType.init(record:)
          )
        }
      }
      callback(newResult)
    }
  }
}
